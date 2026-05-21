"use client";

import { useEffect, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import {
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
} from "firebase/auth";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { auth } from "@/lib/firebase";
import { isAdminEmail } from "@/lib/firestore/admins";

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isSubmitting, setIsSubmitting] = useState(false);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (user) => {
      console.log("[auth] login page state changed", {
        uid: user?.uid || null,
        email: user?.email || null,
      });
      if (!user) return;
      const allowed = await isAdminEmail(user.email);
      console.log("[auth] login page allowlist check", {
        email: user.email || null,
        allowed,
      });
      if (allowed) {
        router.replace("/");
      }
    });

    return () => unsubscribe();
  }, [router]);

  useEffect(() => {
    const timer = setTimeout(() => {
      setEmail("");
      setPassword("");
    }, 0);

    return () => clearTimeout(timer);
  }, []);

  useEffect(() => {
    if (searchParams.get("reason") === "denied") {
      setError("Access denied. Your account is not approved for admin use.");
    }
  }, [searchParams]);

  const handleSubmit = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);

    if (!email.trim() || !password) {
      setError("Email and password are required.");
      return;
    }

    setIsSubmitting(true);

    try {
      console.log("[auth] attempting sign in", { email: email.trim() });
      const credential = await signInWithEmailAndPassword(
        auth,
        email.trim(),
        password,
      );
      const allowed = await isAdminEmail(credential.user.email);
      console.log("[auth] sign in allowlist check", {
        email: credential.user.email || null,
        allowed,
      });
      if (!allowed) {
        await signOut(auth);
        setError("Access denied. This account is not in the admin list.");
        return;
      }
      router.replace("/");
    } catch (err) {
      console.warn("[auth] sign in failed", err);
      setError(err instanceof Error ? err.message : "Failed to sign in");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="relative min-h-screen bg-linear-to-br from-slate-50 via-amber-50 to-sky-50 px-4 py-10">
      <div className="pointer-events-none absolute -right-20 -top-20 h-64 w-64 rounded-full bg-amber-100/70 blur-3xl" />
      <div className="pointer-events-none absolute -bottom-24 left-10 h-72 w-72 rounded-full bg-sky-100/70 blur-3xl" />

      <div className="relative mx-auto flex w-full max-w-4xl items-stretch overflow-hidden rounded-3xl border border-slate-200 bg-white/80 shadow-xl backdrop-blur">
        <div className="hidden w-1/2 flex-col justify-between bg-slate-900 p-10 text-white md:flex">
          <div>
            <p className="text-xs uppercase tracking-[0.4em] text-slate-300">
              Admin access
            </p>
            <h1 className="mt-4 text-3xl font-semibold leading-tight">
              Secure operations hub for the first aid platform.
            </h1>
            <p className="mt-4 text-sm text-slate-300">
              Sign in with your approved email to manage categories, injuries,
              guides, and analytics.
            </p>
          </div>
          <div className="space-y-3 text-sm text-slate-300">
            <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
              Allowlist-controlled access
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
              Firebase-authenticated sessions
            </div>
            <div className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
              Real-time admin dashboard
            </div>
          </div>
        </div>

        <Card className="w-full rounded-none border-0 bg-transparent shadow-none md:w-1/2">
          <CardHeader className="px-8 pt-8">
            <CardTitle className="text-2xl">Admin login</CardTitle>
            <p className="mt-2 text-sm text-slate-500">
              Only approved admins can access the dashboard.
            </p>
          </CardHeader>
          <CardContent className="px-8 pb-8">
            <form
              className="space-y-5"
              onSubmit={handleSubmit}
              autoComplete="off"
            >
              <div>
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Email
                </label>
                <input
                  type="email"
                  name="admin-email"
                  value={email}
                  onChange={(event) => setEmail(event.target.value)}
                  className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-slate-400"
                  placeholder="Email address"
                  autoComplete="off"
                />
              </div>
              <div>
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Password
                </label>
                <input
                  type="password"
                  name="admin-password"
                  value={password}
                  onChange={(event) => setPassword(event.target.value)}
                  className="mt-2 w-full rounded-xl border border-slate-200 bg-white px-3 py-2.5 text-sm text-slate-900 outline-none transition focus:border-slate-400"
                  placeholder="Password"
                  autoComplete="new-password"
                />
              </div>

              {error && (
                <p className="rounded-xl border border-red-100 bg-red-50 px-3 py-2 text-sm text-red-700">
                  {error}
                </p>
              )}

              <Button className="w-full rounded-xl" disabled={isSubmitting}>
                {isSubmitting ? "Signing in..." : "Sign in"}
              </Button>
            </form>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
