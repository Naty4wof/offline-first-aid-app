"use client";

import { useEffect, useMemo, useState } from "react";
import { ChevronDown, ChevronRight, Search } from "lucide-react";

import DataTable from "@/components/data-table";
import { Button } from "@/components/ui/button";
import { getUsers } from "@/lib/users";

type UserRow = {
  id: string;
  name?: string;
  age?: number;
  bloodType?: string;
  medical?: string;
  createdAt?: { toDate?: () => Date } | string;
  isSynced?: boolean;
};

function formatCreatedAt(value?: UserRow["createdAt"]) {
  if (!value) return "-";
  if (typeof value === "string") return value;
  if (typeof value.toDate === "function") {
    return value.toDate().toLocaleDateString();
  }
  return "-";
}

export default function UsersPage() {
  const [query, setQuery] = useState("");
  const [users, setUsers] = useState<UserRow[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const loadUsers = async () => {
      try {
        const data = (await getUsers()) as UserRow[];
        if (isMounted) {
          setUsers(data);
          setExpandedId(null);
        }
      } catch (err) {
        if (isMounted) {
          setError(err instanceof Error ? err.message : "Failed to load users");
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    loadUsers();

    return () => {
      isMounted = false;
    };
  }, []);

  const filteredUsers = useMemo(() => {
    if (!query) return users;
    const lower = query.toLowerCase();
    return users.filter((user) =>
      [user.name, user.bloodType, user.medical]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(lower)),
    );
  }, [query, users]);

  const showSkeleton = loading && !error;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 rounded-2xl border bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
            Users
          </p>
          <h1 className="mt-2 text-2xl font-semibold">User management</h1>
          <p className="mt-1 text-sm text-slate-500">
            Organize roles and keep profiles ready for sync.
          </p>
        </div>
        <div className="flex w-full flex-col gap-3 sm:w-auto sm:flex-row sm:items-center">
          <div className="flex w-full items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600 sm:w-72">
            <Search className="h-4 w-4" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search users"
              className="w-full bg-transparent outline-none"
            />
          </div>
          <Button className="rounded-xl">Add New</Button>
        </div>
      </div>

      {showSkeleton && (
        <div className="space-y-3 rounded-2xl border bg-white p-6 shadow-sm">
          <div className="h-4 w-44 animate-pulse rounded-full bg-slate-100" />
          <div className="grid gap-3">
            {Array.from({ length: 4 }).map((_, index) => (
              <div
                key={`user-skeleton-${index}`}
                className="h-10 animate-pulse rounded-xl bg-slate-100"
              />
            ))}
          </div>
        </div>
      )}
      {error && <p className="text-sm text-red-600">{error}</p>}

      {!loading && !error && (
        <DataTable
          columns={[
            {
              key: "expand",
              header: "",
              className: "w-10 text-right",
              render: (row) =>
                expandedId === row.id ? (
                  <ChevronDown className="h-4 w-4 text-slate-400" />
                ) : (
                  <ChevronRight className="h-4 w-4 text-slate-400" />
                ),
            },
            { key: "name", header: "Name", className: "font-medium" },
            { key: "age", header: "Age" },
            { key: "bloodType", header: "Blood" },
            {
              key: "isSynced",
              header: "Synced",
              render: (row) => (row.isSynced ? "Yes" : "No"),
            },
            {
              key: "actions",
              header: "Actions",
              className: "text-right",
              render: () => (
                <div
                  className="flex justify-end gap-2"
                  onClick={(event) => event.stopPropagation()}
                >
                  <Button variant="outline" className="h-8 rounded-lg px-3">
                    Edit
                  </Button>
                  <Button variant="destructive" className="h-8 rounded-lg px-3">
                    Delete
                  </Button>
                </div>
              ),
            },
          ]}
          data={filteredUsers}
          getRowId={(row) => row.id}
          onRowClick={(row) =>
            setExpandedId((current) => (current === row.id ? null : row.id))
          }
          expandedRowId={expandedId}
          renderExpandedRow={(row) => (
            <div className="max-h-[320px] overflow-auto rounded-xl border border-slate-200 bg-white p-4 text-sm text-slate-600">
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Name
                  </p>
                  <p className="mt-1 break-words text-slate-900">
                    {row.name || "-"}
                  </p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Age
                  </p>
                  <p className="mt-1 text-slate-900">{row.age ?? "-"}</p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Blood Type
                  </p>
                  <p className="mt-1 text-slate-900">{row.bloodType || "-"}</p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Synced
                  </p>
                  <p className="mt-1 text-slate-900">
                    {row.isSynced ? "Yes" : "No"}
                  </p>
                </div>
                <div className="sm:col-span-2">
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Medical
                  </p>
                  <p className="mt-1 whitespace-pre-wrap break-words text-slate-900">
                    {row.medical || "-"}
                  </p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Created
                  </p>
                  <p className="mt-1 text-slate-900">
                    {formatCreatedAt(row.createdAt)}
                  </p>
                </div>
                <div className="sm:col-span-2">
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Document ID
                  </p>
                  <p className="mt-1 break-words text-slate-900">{row.id}</p>
                </div>
              </div>
            </div>
          )}
        />
      )}
    </div>
  );
}
