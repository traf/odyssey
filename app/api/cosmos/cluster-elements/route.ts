import { NextRequest, NextResponse } from "next/server";
import { fetchClusterElements } from "@/lib/cosmos";
import { ElementsResponse, ApiError } from "@/lib/types";

export async function GET(
  req: NextRequest
): Promise<NextResponse<ElementsResponse | ApiError>> {
  const clusterId = req.nextUrl.searchParams.get("clusterId");
  const cursor = req.nextUrl.searchParams.get("cursor");

  if (!clusterId) {
    return NextResponse.json(
      { error: "Missing clusterId" },
      { status: 400 }
    );
  }

  try {
    const result = await fetchClusterElements(
      Number(clusterId),
      cursor || null
    );
    return NextResponse.json({
      elements: result.elements,
      nextCursor: result.nextCursor,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : "Unknown error";
    return NextResponse.json({ error: message }, { status: 502 });
  }
}
