export interface CosmosElement {
  id: number;
  url: string;
  width: number | null;
  height: number | null;
  type: "image" | "video";
  sourceUrl: string | null;
  // Upstream palette, dominant swatch first. Empty for older elements Cosmos
  // never extracted, and for search hits (`ElementTile` doesn't expose it).
  colors: string[];
}

export interface UserProfile {
  id: string;
  username: string;
  displayName: string;
  avatarUrl: string | null;
}

export interface ResolveResponse {
  user: UserProfile;
  elements: CosmosElement[];
  nextCursor: string | null;
  totalCount: number;
}

export interface ElementsResponse {
  elements: CosmosElement[];
  nextCursor: string | null;
}

export interface CosmosCluster {
  id: number;
  name: string;
  slug: string;
  numberOfElements: number;
  coverImageUrl: string | null;
}

export interface ClustersResponse {
  clusters: CosmosCluster[];
}

export interface ApiError {
  error: string;
}
