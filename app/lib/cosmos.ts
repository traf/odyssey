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
      filters: { contentType: IMAGE }
      meta: { pageSize: 40, pageCursor: $cursor }
    ) {
      items {
        id
        type
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

  const elements: CosmosElement[] = result.items
    .filter((item) => item.image?.url)
    .map((item) => ({
      id: item.id,
      url: item.image!.url,
      width: item.image!.width || null,
      height: item.image!.height || null,
      type: "image" as const,
    }));

  return {
    elements,
    nextCursor: result.meta.nextPageCursor,
    totalCount: result.meta.count,
  };
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

  const elements: CosmosElement[] = result.items
    .filter((item) => item.image?.url)
    .map((item) => ({
      id: item.id,
      url: item.image!.url,
      width: item.image!.width || null,
      height: item.image!.height || null,
      type: "image" as const,
    }));

  return {
    elements,
    nextCursor: result.meta.nextPageCursor,
    totalCount: result.meta.count,
  };
}
