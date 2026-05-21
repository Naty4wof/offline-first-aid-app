"use client";

import { useEffect, useMemo, useState } from "react";
import { usePathname, useRouter } from "next/navigation";
import { onAuthStateChanged, signOut } from "firebase/auth";

import Sidebar from "@/components/sidebar";
import Topbar from "@/components/topbar";
import { auth } from "@/lib/firebase";
import { isAdminEmail } from "@/lib/firestore/admins";
import { getCategories } from "@/lib/firestore/categories";
import { getGuides } from "@/lib/firestore/guides";
import { getInjuries } from "@/lib/firestore/injuries";
import { getUsers } from "@/lib/users";

type AdminShellProps = {
  children: React.ReactNode;
};

type AuthState =
  | { status: "loading" }
  | { status: "guest" }
  | { status: "denied" }
  | { status: "authed"; email: string };

export default function AdminShell({ children }: AdminShellProps) {
  const [sidebarOpen, setSidebarOpen] = useState(false);
  const [authState, setAuthState] = useState<AuthState>({
    status: "loading",
  });
  const router = useRouter();
  const pathname = usePathname();
  const isLoginRoute = pathname === "/login";
  const isAuthed = authState.status === "authed";

  useEffect(() => {
    let isMounted = true;

    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      if (!isMounted) return;
      console.log("[auth] state changed", {
        uid: user?.uid || null,
        email: user?.email || null,
      });
      if (!user) {
        console.log("[auth] no user, redirecting to login");
        setAuthState({ status: "guest" });
        return;
      }

      const allowed = await isAdminEmail(user.email);
      console.log("[auth] admin allowlist check", {
        email: user.email || null,
        allowed,
      });
      if (!allowed) {
        console.warn("[auth] access denied, signing out");
        await signOut(auth);
        if (isMounted) setAuthState({ status: "denied" });
        return;
      }

      setAuthState({ status: "authed", email: user.email ?? "" });
    });

    return () => {
      isMounted = false;
      unsubscribe();
    };
  }, []);

  useEffect(() => {
    if (isLoginRoute) return;
    if (authState.status === "guest") {
      console.log("[auth] redirecting guest to /login");
      router.replace("/login");
    }
    if (authState.status === "denied") {
      console.log("[auth] redirecting denied user to /login?reason=denied");
      router.replace("/login?reason=denied");
    }
  }, [authState.status, isLoginRoute, router]);

  useEffect(() => {
    if (!isAuthed) return;
    void Promise.allSettled([
      getCategories(),
      getInjuries(),
      getGuides(),
      getUsers(),
    ]);
  }, [isAuthed]);

  const shellContent = useMemo(() => {
    if (isLoginRoute) return children;
    if (!isAuthed) {
      return (
        <div className="flex min-h-screen items-center justify-center bg-slate-50 text-slate-600">
          <div className="rounded-2xl border bg-white px-6 py-5 text-sm shadow-sm">
            Checking admin access...
          </div>
        </div>
      );
    }

    return (
      <div className="min-h-screen bg-slate-50 text-slate-900">
        <div className="flex">
          <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
          <div className="flex min-h-screen flex-1 flex-col">
            <Topbar onMenuClick={() => setSidebarOpen(true)} />
            <main className="flex-1 px-4 py-6 sm:px-6 lg:px-8">{children}</main>
          </div>
        </div>
      </div>
    );
  }, [children, isAuthed, isLoginRoute, sidebarOpen]);

  return shellContent;
}
