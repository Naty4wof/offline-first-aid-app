"use client";

import { useEffect, useMemo, useState } from "react";

import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { getCategories, type Category } from "@/lib/firestore/categories";
import { getGuides } from "@/lib/firestore/guides";
import { getInjuries, type Injury } from "@/lib/firestore/injuries";
import { getUsers } from "@/lib/users";

type GuideEntry = { injuryId?: string };

const maxInjuriesPerCategory = 2;

function DonutChart({ percent, label }: { percent: number; label: string }) {
  const clamped = Math.max(0, Math.min(100, percent));
  return (
    <div className="flex items-center gap-4">
      <div
        className="h-24 w-24 rounded-full"
        style={{
          background: `conic-gradient(#0f172a ${clamped}%, #e2e8f0 0%)`,
        }}
        aria-label={label}
        role="img"
      />
      <div>
        <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
          {label}
        </p>
        <p className="mt-2 text-3xl font-semibold text-slate-900">{clamped}%</p>
        <p className="mt-1 text-sm text-slate-500">
          Portion of injuries covered by guides
        </p>
      </div>
    </div>
  );
}

export default function Home() {
  const [users, setUsers] = useState<Array<{ id: string }>>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [injuries, setInjuries] = useState<Injury[]>([]);
  const [guides, setGuides] = useState<GuideEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const loadDashboard = async () => {
      try {
        const [userData, categoryData, injuryData, guideData] =
          await Promise.all([
            getUsers(),
            getCategories(),
            getInjuries(),
            getGuides(),
          ]);
        if (isMounted) {
          setUsers(userData as Array<{ id: string }>);
          setCategories(categoryData);
          setInjuries(injuryData);
          setGuides(guideData as GuideEntry[]);
        }
      } catch (err) {
        if (isMounted) {
          setError(
            err instanceof Error ? err.message : "Failed to load dashboard",
          );
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    loadDashboard();

    return () => {
      isMounted = false;
    };
  }, []);

  const injuryCountByCategory = useMemo(() => {
    return injuries.reduce<Record<string, number>>((acc, injury) => {
      acc[injury.categoryId] = (acc[injury.categoryId] || 0) + 1;
      return acc;
    }, {});
  }, [injuries]);

  const guideCountByInjury = useMemo(() => {
    return guides.reduce<Record<string, number>>((acc, guide) => {
      const key = guide.injuryId || "";
      if (!key) return acc;
      acc[key] = (acc[key] || 0) + 1;
      return acc;
    }, {});
  }, [guides]);

  const guideCountByCategory = useMemo(() => {
    return injuries.reduce<Record<string, number>>((acc, injury) => {
      const guideCount = guideCountByInjury[injury.id] || 0;
      acc[injury.categoryId] = (acc[injury.categoryId] || 0) + guideCount;
      return acc;
    }, {});
  }, [injuries, guideCountByInjury]);

  const injuriesWithGuides = useMemo(() => {
    const withGuide = new Set<string>();
    guides.forEach((guide) => {
      if (guide.injuryId) withGuide.add(guide.injuryId);
    });
    return withGuide;
  }, [guides]);

  const categoryInsights = useMemo(() => {
    const ranked = categories
      .map((category) => {
        const injuriesCount = injuryCountByCategory[category.id] || 0;
        const guideCount = guideCountByCategory[category.id] || 0;
        return {
          id: category.id,
          name: category.name,
          injuriesCount,
          guideCount,
        };
      })
      .sort((a, b) => b.injuriesCount - a.injuriesCount);

    return ranked.slice(0, 5);
  }, [categories, injuryCountByCategory, guideCountByCategory]);

  const summaryStats = useMemo(
    () => [
      { label: "Total users", value: users.length.toLocaleString() },
      { label: "Total categories", value: categories.length.toString() },
      { label: "Total injuries", value: injuries.length.toString() },
      { label: "Total guides", value: guides.length.toString() },
    ],
    [users.length, categories.length, injuries.length, guides.length],
  );

  const injuriesWithGuidesCount = injuries.filter((injury) =>
    injuriesWithGuides.has(injury.id),
  ).length;
  const injuriesWithoutGuidesCount = injuries.length - injuriesWithGuidesCount;
  const guideCoveragePercent =
    injuries.length === 0
      ? 0
      : Math.round((injuriesWithGuidesCount / injuries.length) * 100);

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 rounded-2xl border bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
            Dashboard
          </p>
          <h1 className="mt-2 text-3xl font-semibold text-slate-900">
            Operational snapshot
          </h1>
          <p className="mt-2 text-sm text-slate-500">
            Live metrics for content coverage and admin activity.
          </p>
        </div>
      </div>

      {loading && (
        <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
          {Array.from({ length: 4 }).map((_, index) => (
            <Card
              key={`stat-skeleton-${index}`}
              className="rounded-2xl shadow-sm"
            >
              <CardHeader>
                <div className="h-3 w-24 animate-pulse rounded-full bg-slate-100" />
              </CardHeader>
              <CardContent>
                <div className="h-8 w-20 animate-pulse rounded-full bg-slate-100" />
              </CardContent>
            </Card>
          ))}
        </section>
      )}

      {error && <p className="text-sm text-red-600">{error}</p>}

      {!loading && !error && (
        <>
          <section className="grid gap-4 sm:grid-cols-2 xl:grid-cols-4">
            {summaryStats.map((stat) => (
              <Card key={stat.label} className="rounded-2xl shadow-sm">
                <CardHeader>
                  <CardTitle className="text-xs uppercase tracking-[0.2em] text-slate-500">
                    {stat.label}
                  </CardTitle>
                </CardHeader>
                <CardContent className="text-4xl font-semibold text-slate-900">
                  {stat.value}
                </CardContent>
              </Card>
            ))}
          </section>

          <section className="grid gap-4 lg:grid-cols-3">
            <Card className="rounded-2xl shadow-sm lg:col-span-2">
              <CardHeader>
                <CardTitle className="text-base">Category insights</CardTitle>
              </CardHeader>
              <CardContent className="space-y-4">
                {categoryInsights.length === 0 && (
                  <p className="text-sm text-slate-500">
                    Add categories to see coverage details.
                  </p>
                )}
                {categoryInsights.map((row) => (
                  <div
                    key={row.id}
                    className="flex flex-wrap items-center justify-between gap-3 rounded-xl border border-slate-100 bg-slate-50 px-4 py-3"
                  >
                    <div>
                      <p className="text-sm font-semibold text-slate-900">
                        {row.name}
                      </p>
                      <p className="mt-1 text-xs text-slate-500">
                        Max injuries allowed: {maxInjuriesPerCategory}
                      </p>
                    </div>
                    <div className="flex items-center gap-4 text-xs text-slate-500">
                      <span className="text-sm font-semibold text-slate-900">
                        {row.injuriesCount} injuries
                      </span>
                      <span>{row.guideCount} guides</span>
                    </div>
                  </div>
                ))}
              </CardContent>
            </Card>

            <Card className="rounded-2xl shadow-sm">
              <CardHeader>
                <CardTitle className="text-base">Guide coverage</CardTitle>
              </CardHeader>
              <CardContent className="space-y-6">
                <DonutChart percent={guideCoveragePercent} label="Coverage" />
                <div className="grid gap-3 text-sm">
                  <div className="flex items-center justify-between">
                    <span className="text-slate-500">Injuries with guides</span>
                    <span className="font-semibold text-slate-900">
                      {injuriesWithGuidesCount}
                    </span>
                  </div>
                  <div className="flex items-center justify-between">
                    <span className="text-slate-500">
                      Injuries without guides
                    </span>
                    <span className="font-semibold text-slate-900">
                      {injuriesWithoutGuidesCount}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>
          </section>
        </>
      )}
    </div>
  );
}
