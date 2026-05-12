"use client";

import { useEffect, useState } from "react";
import { getUsers } from "@/lib/users";

export default function UsersPage() {
  const [users, setUsers] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

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
    <div>
      <h1>Users</h1>

      {loading && <p>Loading...</p>}
      {error && <p style={{ color: "#dc2626" }}>{error}</p>}

      {!loading && !error && (
        <>
          {users.map((user: any) => (
            <div
              key={user.id}
              style={{ border: "1px solid #ccc", margin: 10, padding: 10 }}
            >
              <p>
                <strong>Name:</strong> {user.name}
              </p>
              <p>
                <strong>Medical:</strong> {user.medicalInfo}
              </p>
            </div>
          ))}
        </>
      )}
    </div>
  );
}
