import { CosmosElement, CosmosCluster, UserProfile } from "./types";

const API_URL = "https://api.www.cosmos.so/graphql";
const HEADERS = {
  "User-Agent":
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
  "Content-Type": "application/json",
  Origin: "https://www.cosmos.so",
};

// ---------------------------------------------------------------------------
// GraphQL helper
// ---------------------------------------------------------------------------

async function gql<T>(query: string, variables: Record<string, unknown> = {}): Promise<T> {
  const res = await fetch(API_URL, {
    method: "POST",
    headers: HEADERS,
    body: JSON.stringify({ query, variables }),
  });

  if (!res.ok) {
    throw new Error(`Cosmos API error: ${res.status}`);
  }

  const json = await res.json();

  if (json.errors?.length) {
    throw new Error(json.errors[0].message || "GraphQL error");
  }

  return json.data as T;
}

// ---------------------------------------------------------------------------
// Resolve username → user profile + first page of elements
// ---------------------------------------------------------------------------

const USER_QUERY = `
  query ($username: String!) {
    user(username: $username) {
      id
      username
      fullName
      avatarUrl
    }
  }
`;

const ELEMENTS_QUERY = `
  query ($ownerId: UserId!, $cursor: String) {
    userPublicElementsV1(
      userId: $ownerId
      filters: {}
      meta: { pageSize: 40, pageCursor: $cursor }
    ) {
      items {
        id
        type
        sourceUrl
        createdAt
        image { url width height }
      }
      meta { nextPageCursor count }
    }
  }
`;

interface UserQueryResult {
  user: {
    id: number;
    username: string;
    fullName: string | null;
    avatarUrl: string | null;
  } | null;
}

interface ElementsQueryResult {
  userPublicElementsV1: {
    items: Array<{
      id: number;
      type: string;
      sourceUrl: string | null;
      createdAt: string | null;
      image: { url: string; width: number; height: number } | null;
    }>;
    meta: {
      nextPageCursor: string | null;
      count: number;
    };
  };
}

interface ResolveResult {
  user: UserProfile;
  elements: CosmosElement[];
  nextCursor: string | null;
  totalCount: number;
}

export async function resolveUser(username: string): Promise<ResolveResult> {
  // Step 1: Resolve username → user ID
  const { user: raw } = await gql<UserQueryResult>(USER_QUERY, { username });

  if (!raw) {
    throw new Error("User not found");
  }

  const user: UserProfile = {
    id: String(raw.id),
    username: raw.username,
    displayName: (raw.fullName || "").trim() || raw.username,
    avatarUrl: raw.avatarUrl,
  };

  // Step 2: Fetch first page of elements
  const { elements, nextCursor, totalCount } = await fetchElements(
    user.id,
    null
  );

  return { user, elements, nextCursor, totalCount };
}

// ---------------------------------------------------------------------------
// Paginated element fetch
// ---------------------------------------------------------------------------

interface FetchResult {
  elements: CosmosElement[];
  nextCursor: string | null;
  totalCount: number;
}

export async function fetchElements(
  userId: string,
  cursor: string | null
): Promise<FetchResult> {
  const data = await gql<ElementsQueryResult>(ELEMENTS_QUERY, {
    ownerId: userId,
    cursor,
  });

  const result = data.userPublicElementsV1;

  return {
    elements: mapElements(result.items),
    nextCursor: result.meta.nextPageCursor,
    totalCount: result.meta.count,
  };
}

// Filters to images, sorts newest-added first (Cosmos returns cluster elements
// in an arbitrary order), and maps to the public shape.
function mapElements(
  items: Array<{
    id: number;
    sourceUrl: string | null;
    createdAt: string | null;
    image: { url: string; width: number; height: number } | null;
  }>
): CosmosElement[] {
  return items
    .filter((item) => item.image?.url)
    .sort((a, b) => new Date(b.createdAt ?? 0).getTime() - new Date(a.createdAt ?? 0).getTime())
    .map((item) => ({
      id: item.id,
      url: item.image!.url,
      width: item.image!.width || null,
      height: item.image!.height || null,
      type: "image" as const,
      sourceUrl: item.sourceUrl,
    }));
}

// ---------------------------------------------------------------------------
// Clusters
// ---------------------------------------------------------------------------

const CLUSTERS_QUERY = `
  query ($filters: ClusterListFilters) {
    clusters(filters: $filters) {
      items {
        id
        name
        slug
        numberOfElements
        coverImageUrl
      }
      meta { count }
    }
  }
`;

interface ClustersQueryResult {
  clusters: {
    items: Array<{
      id: number;
      name: string;
      slug: string;
      numberOfElements: number;
      coverImageUrl: string | null;
    }>;
    meta: { count: number };
  };
}

export async function fetchClusters(userId: string): Promise<CosmosCluster[]> {
  const data = await gql<ClustersQueryResult>(CLUSTERS_QUERY, {
    filters: { isPrivate: false, ownerId: Number(userId) },
  });

  return data.clusters.items;
}

// ---------------------------------------------------------------------------
// Cluster elements (paginated)
// ---------------------------------------------------------------------------

const CLUSTER_ELEMENTS_QUERY = `
  query ($filters: ElementListFilters, $meta: ListMetadataInput) {
    elements(filters: $filters, meta: $meta) {
      items {
        id
        type
        sourceUrl
        createdAt
        image { url width height }
      }
      meta { nextPageCursor count }
    }
  }
`;

interface ClusterElementsQueryResult {
  elements: {
    items: Array<{
      id: number;
      type: string;
      sourceUrl: string | null;
      createdAt: string | null;
      image: { url: string; width: number; height: number } | null;
    }>;
    meta: {
      nextPageCursor: string | null;
      count: number;
    };
  };
}

export async function fetchClusterElements(
  clusterId: number,
  cursor: string | null
): Promise<FetchResult> {
  const data = await gql<ClusterElementsQueryResult>(CLUSTER_ELEMENTS_QUERY, {
    filters: { clusterId },
    meta: { pageSize: 40, pageCursor: cursor },
  });

  const result = data.elements;

  return {
    elements: mapElements(result.items),
    nextCursor: result.meta.nextPageCursor,
    totalCount: result.meta.count,
  };
}

// ---------------------------------------------------------------------------
// Global search (paginated)
// ---------------------------------------------------------------------------

// `searchElements` returns the `ElementTile` interface rather than the flat
// element type the other queries use, so the media has to come off the
// `ElementWithMediaTile` variant via an inline fragment.
const SEARCH_QUERY = `
  query ($searchTerm: String!, $meta: ListMetadataInput) {
    searchElements(searchTerm: $searchTerm, meta: $meta) {
      items {
        id
        source { url }
        ... on ElementWithMediaTile {
          media { url width height }
        }
      }
      meta { nextPageCursor count }
    }
  }
`;

interface SearchQueryResult {
  searchElements: {
    items: Array<{
      id: number;
      source: { url: string | null } | null;
      media: { url: string; width: number; height: number } | null;
    }>;
    meta: {
      nextPageCursor: string | null;
      count: number;
    };
  };
}

export async function searchElements(
  searchTerm: string,
  cursor: string | null
): Promise<FetchResult> {
  const data = await gql<SearchQueryResult>(SEARCH_QUERY, {
    searchTerm,
    meta: { pageSize: 40, pageCursor: cursor },
  });

  const result = data.searchElements;

  return {
    // Upstream orders these by relevance, so unlike the profile feeds they must
    // never be re-sorted by date.
    elements: result.items
      .filter((item) => item.media?.url)
      .map((item) => ({
        id: item.id,
        url: item.media!.url,
        width: item.media!.width || null,
        height: item.media!.height || null,
        type: "image" as const,
        sourceUrl: item.source?.url ?? null,
      })),
    nextCursor: result.meta.nextPageCursor,
    totalCount: result.meta.count,
  };
}
