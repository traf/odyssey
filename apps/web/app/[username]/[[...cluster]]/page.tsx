import Profile from "@/components/Profile";

export default async function ProfilePage({
  params,
}: {
  params: Promise<{ username: string; cluster?: string[] }>;
}) {
  const { username, cluster } = await params;

  return <Profile initialUsername={username} initialClusterSlug={cluster?.[0]} />;
}
