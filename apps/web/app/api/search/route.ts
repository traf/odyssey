import { NextRequest, NextResponse } from "next/server";
import { searchElements } from "@/lib/cosmos";
import { cached } from "@/lib/cache";

export async function GET(req: NextRequest) {
  const q = req.nextUrl.searchParams.get("q");

  if (!q) {
    return NextResponse.json({ error: "Missing q" }, { status: 400 });
  }

  try {
    const result = await cached(`search:${q.toLowerCase()}`, async () => {
      // Top page only. Unlike the profile routes there's no paging loop here:
      // upstream caps search at 500 matches and each page is its own round
      // trip, so draining them all would risk the function timeout for results
      // nobody scrolls to.
      const { elements } = await searchElements(q, null);
      const images = elements.map((e) => e.url);
      return { images, count: images.length };
    });

    return NextResponse.json(result);
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 500 });
  }
}
