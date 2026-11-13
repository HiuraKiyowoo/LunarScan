// DOWNLOAD A CHAPTER'S TRANSLATED PAGES AS A ZIP (fflate).
// IMPORTED DEP-MODULES
import { error } from '@sveltejs/kit';
import { eq } from 'drizzle-orm';
import { readFile } from 'node:fs/promises';
import { extname, join } from 'node:path';
import { zipSync } from 'fflate';
// IMPORTED MODULES
import { assertChapterExists } from '$lib/server/chapters';
import { chapterArchiveName, zipContentDisposition } from '$lib/utils/chapter-export';
import { db } from '$lib/server/db';
import { pages } from '$lib/server/db/schema';
import { DATA_ROOT } from '$lib/server/paths';
import type { RequestHandler } from './$types';

export const GET: RequestHandler = async ({ params, url }) => {
	const chapterId = Number(params.id);
	if (!Number.isInteger(chapterId)) throw error(400, 'Invalid chapter id.');
	const chapter = await assertChapterExists(chapterId);
	const mode = url.searchParams.get('mode') === 'redraw' ? 'redraw' : 'translated';

	const done = db.select().from(pages).where(eq(pages.chapterId, chapterId)).orderBy(pages.seq).all();

	// FOLDER-BASED ZIP - THE ARCHIVE UNPACKS INTO ONE CHAPTER FOLDER HOLDING THE PAGES, WHICH IS
	// THE STRUCTURE MIHON/TACHIYOMI LOCAL SOURCES EXPECT (<book>/<chapter>/images).
	// THE SAME NAME THE CLIENT GIVES THE DOWNLOAD: THE TRANSLATED TITLE WHEN THERE IS ONE (FEAT-009 PHASE 7)
	const safeTitle = chapterArchiveName(chapter.titleTarget || chapter.title, `chapter_${chapterId}`);
	const archiveName = mode === 'redraw'
		? chapterArchiveName(`${safeTitle}_redraw`, `chapter_${chapterId}_redraw`)
		: safeTitle;

	// IMAGES ARE ALREADY COMPRESSED: STORE THEM (LEVEL 0) SO A BIG CHAPTER DOES NOT BLOCK THE EVENT LOOP ON A
	// USELESS DEFLATE PASS. ONLY THE TEXT NOTE IS COMPRESSED.
	const files: Record<string, [Uint8Array, { level: 0 | 6 }]> = {};
	const missing: string[] = [];
	let exported = 0;
	for (const p of done) {
		// REDRAW EXPORTS USE ONLY THE CLEANED IMAGE, NEVER TYPESET OUTPUT OR SOURCE FALLBACKS.
		// NORMAL EXPORT KEEPS ITS EXISTING OUTPUT-THEN-ORIGINAL BEHAVIOR.
		const candidates = (mode === 'redraw' ? [p.cleanedPath] : [p.outputPath, p.filePath]).filter(
			(c): c is string => Boolean(c),
		);
		let added = false;
		for (const rel of candidates) {
			try {
				// ASYNC READ: A LARGE CHAPTER NO LONGER BLOCKS THE EVENT LOOP
				const bytes = await readFile(join(DATA_ROOT, rel));
				// ORIGINALS ARE ALWAYS WEBP (GLOBAL WEBP POLICY) WHILE TYPESET OUTPUT IS PNG: DERIVE THE ENTRY
				// EXTENSION FROM THE ACTUAL FILE INSTEAD OF HARDCODING ".png".
				const ext = extname(rel).toLowerCase() || '.webp';
				files[`${safeTitle}/${String(p.seq).padStart(3, '0')}${ext}`] = [new Uint8Array(bytes), { level: 0 }];
				exported++;
				added = true;
				break;
			} catch {
				// TRY THE NEXT CANDIDATE
			}
		}
		if (!added) {
			const reason = candidates.length === 0 ? 'no image recorded' : 'image file missing or unreadable';
			missing.push(`Page ${p.seq + 1}: ${reason}`);
		}
	}
	if (exported === 0) {
		if (done.length === 0) throw error(404, 'This chapter has no pages yet.');
		if (mode === 'redraw') throw error(404, 'No redrawn pages are available yet. Translate the chapter first.');
		throw error(404, 'No readable page images are available for this chapter.');
	}

	if (missing.length > 0) {
		const note = `These pages could not be included:\n${missing.join('\n')}\n`;
		files[`${safeTitle}/MISSING_PAGES.txt`] = [new TextEncoder().encode(note), { level: 6 }];
	}

	const zipped = zipSync(files);
	const headers: Record<string, string> = {
		'content-type': 'application/zip',
		'content-disposition': zipContentDisposition(archiveName, `chapter_${chapterId}`),
		'x-export-mode': mode,
		// A KNOWN LENGTH MAKES THE CLIENT'S PROGRESS BAR REAL
		'content-length': String(zipped.byteLength),
	};
	if (missing.length > 0) headers['x-missing-pages'] = String(missing.length);
	return new Response(zipped, { headers });
};
