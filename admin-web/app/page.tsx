"use client";

import { useEffect, useMemo, useState } from "react";
import { getUsers } from "@/lib/users";
import {
  BadgeCheck,
  Bell,
  Building2,
  ClipboardCheck,
  LayoutGrid,
  Search,
  Settings,
  Users,
} from "lucide-react";

import { Avatar, AvatarFallback } from "@/components/ui/avatar";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

export default function Home() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const summary = useMemo(() => {
    const total = users.length;
    const pending = users.filter((user) => !user.isSynced).length;
    return {
      total,
      pending,
      synced: Math.max(total - pending, 0),
    };
  }, [users]);

  useEffect(() => {
    let isMounted = true;

    const load = async () => {
      try {
        const data = await getUsers();
        if (isMounted) setUsers(data);
      } catch (err) {
        if (isMounted) {
          setError(err instanceof Error ? err.message : "Failed to load users");
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    load();

    return () => {
      isMounted = false;
    };
  }, []);

  return (
    <div className="min-h-screen bg-muted/30">
      <div className="mx-auto flex w-full max-w-350 gap-5 px-4 py-5 sm:px-6 lg:px-8">
        <aside className="hidden w-64 flex-col gap-4 lg:flex">
          <div className="rounded-2xl border bg-card p-4 shadow-sm">
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-primary text-primary-foreground">
                <LayoutGrid className="h-5 w-5" />
              </div>
              <div>
                <p className="text-sm font-semibold">AidFleet Admin</p>
                <p className="text-xs text-muted-foreground">Control center</p>
              </div>
            </div>
          </div>

          <nav className="space-y-1 text-sm">
            {[
              { label: "Overview", icon: LayoutGrid },
              { label: "Users", icon: Users },
              { label: "Hospitals", icon: Building2 },
              { label: "Approvals", icon: ClipboardCheck },
              { label: "Settings", icon: Settings },
            ].map((item) => (
              <button
                key={item.label}
                className={
                  item.label === "Overview"
                    ? "flex w-full items-center gap-3 rounded-xl bg-primary/10 px-3 py-2 text-left font-semibold text-primary"
                    : "flex w-full items-center gap-3 rounded-xl px-3 py-2 text-left text-muted-foreground hover:bg-muted/70"
                }
              >
                <item.icon className="h-4 w-4" />
                {item.label}
              </button>
            ))}
          </nav>

          <Card className="shadow-sm">
            <CardHeader>
              <CardTitle className="text-sm">Admin actions</CardTitle>
              <CardDescription>Quick links</CardDescription>
            </CardHeader>
            <CardContent className="space-y-2 text-sm text-muted-foreground">
              <p>Review 6 hospital requests</p>
              <p>Approve 12 user profiles</p>
              <p>Check sync queue</p>
            </CardContent>
          </Card>
        </aside>

        <main className="flex-1 space-y-5">
          <Card className="shadow-sm">
            <CardContent className="flex flex-col gap-4 p-5 sm:flex-row sm:items-center sm:justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.2em] text-muted-foreground">
                  Admin dashboard
                </p>
                <h1 className="mt-2 text-2xl font-semibold">Welcome back</h1>
                <p className="mt-1 text-sm text-muted-foreground">
                  Manage users, hospitals, and approvals in one place.
                </p>
              </div>
              <div className="flex items-center gap-3">
                <div className="hidden items-center gap-2 rounded-full border bg-background px-3 py-2 text-sm text-muted-foreground md:flex">
                  <Search className="h-4 w-4" />
                  Search
                </div>
                <Button variant="outline" size="icon">
                  <Bell className="h-4 w-4" />
                </Button>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" className="h-auto p-0">
                      <Avatar className="h-9 w-9">
                        <AvatarFallback>MG</AvatarFallback>
                      </Avatar>
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem>Profile</DropdownMenuItem>
                    <DropdownMenuItem>Settings</DropdownMenuItem>
                    <DropdownMenuItem>Logout</DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </div>
            </CardContent>
          </Card>

          <section className="grid gap-4 md:grid-cols-3">
            <Card className="shadow-sm">
              <CardHeader>
                <CardDescription>Total users</CardDescription>
                <CardTitle className="text-3xl">
                  {summary.total.toLocaleString()}
                </CardTitle>
              </CardHeader>
              <CardContent className="text-sm text-muted-foreground">
                {summary.synced.toLocaleString()} synced
              </CardContent>
            </Card>
            <Card className="shadow-sm">
              <CardHeader>
                <CardDescription>Pending profiles</CardDescription>
                <CardTitle className="text-3xl">
                  {summary.pending.toLocaleString()}
                </CardTitle>
              </CardHeader>
              <CardContent className="text-sm text-muted-foreground">
                Needs verification
              </CardContent>
            </Card>
            <Card className="shadow-sm">
              <CardHeader>
                <CardDescription>Hospitals onboarded</CardDescription>
                <CardTitle className="text-3xl">42</CardTitle>
              </CardHeader>
              <CardContent className="text-sm text-muted-foreground">
                3 awaiting review
              </CardContent>
            </Card>
          </section>

          <section className="grid gap-4 xl:grid-cols-[2fr_1fr]">
            <Card className="shadow-sm">
              <CardHeader>
                <CardTitle>Recent users</CardTitle>
                <CardDescription>Newest onboarding activity</CardDescription>
              </CardHeader>
              <CardContent>
                {loading && (
                  <p className="text-sm text-muted-foreground">Loading...</p>
                )}
                {error && <p className="text-sm text-destructive">{error}</p>}

                {!loading && !error && (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Name</TableHead>
                        <TableHead>Blood</TableHead>
                        <TableHead>Age</TableHead>
                        <TableHead>Status</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {users.slice(0, 6).map((user: any) => (
                        <TableRow key={user.id}>
                          <TableCell className="font-medium">
                            {user.name || "Unnamed"}
                          </TableCell>
                          <TableCell>{user.bloodType || "-"}</TableCell>
                          <TableCell>{user.age || "-"}</TableCell>
                          <TableCell>
                            {user.isSynced ? (
                              <Badge variant="secondary" className="gap-1">
                                <BadgeCheck className="h-3 w-3" /> Synced
                              </Badge>
                            ) : (
                              <Badge variant="outline">Pending</Badge>
                            )}
                          </TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
              </CardContent>
            </Card>

            <div className="space-y-4">
              <Card className="shadow-sm">
                <CardHeader>
                  <CardTitle>Hospital verification</CardTitle>
                  <CardDescription>Monthly target</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="space-y-3">
                    <div className="flex items-center justify-between text-sm">
                      <span>Reviewed</span>
                      <span className="font-semibold">68%</span>
                    </div>
                    <div className="h-2 rounded-full bg-muted">
                      <div className="h-2 w-[68%] rounded-full bg-primary"></div>
                    </div>
                    <p className="text-xs text-muted-foreground">
                      41 of 60 hospitals reviewed
                    </p>
                  </div>
                </CardContent>
              </Card>

              <Card className="shadow-sm">
                <CardHeader>
                  <CardTitle>Quick stats</CardTitle>
                  <CardDescription>Today</CardDescription>
                </CardHeader>
                <CardContent className="space-y-3 text-sm">
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">New users</span>
                    <span className="font-semibold">12</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Approvals</span>
                    <span className="font-semibold">9</span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-muted-foreground">Flags</span>
                    <span className="font-semibold">2</span>
                  </div>
                </CardContent>
              </Card>
            </div>
          </section>
        </main>
      </div>
    </div>
  );
}
