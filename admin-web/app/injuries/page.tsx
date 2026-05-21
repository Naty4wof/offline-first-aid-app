"use client";

import { useEffect, useMemo, useState } from "react";
import { ChevronDown, ChevronRight, Search } from "lucide-react";

import DataTable from "@/components/data-table";
import { Button } from "@/components/ui/button";
import {
  createInjury,
  deleteInjury,
  getInjuries,
  updateInjury,
  type Injury,
} from "@/lib/firestore/injuries";
import { getCategories, type Category } from "@/lib/firestore/categories";
import { getGuides } from "@/lib/firestore/guides";

function renderList(items?: string[]) {
  if (!items || items.length === 0) {
    return <p className="mt-1 text-slate-900">-</p>;
  }

  return (
    <ul className="mt-1 list-disc space-y-1 pl-5 text-slate-900">
      {items.map((item, index) => (
        <li key={`${item}-${index}`} className="wrap-break-word">
          {item}
        </li>
      ))}
    </ul>
  );
}

export default function InjuriesPage() {
  const [query, setQuery] = useState("");
  const [injuries, setInjuries] = useState<Injury[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [guideCounts, setGuideCounts] = useState<Record<string, number>>({});
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formValues, setFormValues] = useState({
    id: "",
    title: "",
    categoryId: "",
    severity: "",
    keywords: [""],
  });
  const [editingInjury, setEditingInjury] = useState<Injury | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const loadInjuries = async () => {
      try {
        const [injuryData, categoryData] = await Promise.all([
          getInjuries(),
          getCategories(),
        ]);
        const guideData = (await getGuides()) as Array<{ injuryId?: string }>;
        if (isMounted) {
          setInjuries(injuryData);
          setCategories(categoryData);
          setGuideCounts(
            guideData.reduce<Record<string, number>>((acc, guide) => {
              const key = guide.injuryId || "";
              if (!key) return acc;
              acc[key] = (acc[key] || 0) + 1;
              return acc;
            }, {}),
          );
          setExpandedId(null);
        }
      } catch (err) {
        if (isMounted) {
          setError(
            err instanceof Error ? err.message : "Failed to load injuries",
          );
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    loadInjuries();

    return () => {
      isMounted = false;
    };
  }, []);

  const categoryNameById = useMemo(() => {
    return categories.reduce<Record<string, string>>((acc, category) => {
      acc[category.id] = category.name;
      return acc;
    }, {});
  }, [categories]);

  const injuryCountByCategory = useMemo(() => {
    return injuries.reduce<Record<string, number>>((acc, injury) => {
      acc[injury.categoryId] = (acc[injury.categoryId] || 0) + 1;
      return acc;
    }, {});
  }, [injuries]);

  const availableCategoriesForCreate = useMemo(() => {
    return categories.filter(
      (category) => (injuryCountByCategory[category.id] || 0) === 0,
    );
  }, [categories, injuryCountByCategory]);

  const filteredInjuries = useMemo(() => {
    if (!query) return injuries;
    const lower = query.toLowerCase();
    return injuries.filter((injury) =>
      [
        injury.title,
        injury.categoryId,
        categoryNameById[injury.categoryId],
        injury.severity,
        injury.keywords?.join(" "),
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(lower)),
    );
  }, [query, injuries, categoryNameById]);

  const showSkeleton = loading && !error;

  const normalizeArray = (items?: string[]) =>
    items && items.length > 0 ? items : [""];

  const createEmptyFormValues = (categoryId: string) => ({
    id: "",
    title: "",
    categoryId,
    severity: "",
    keywords: [""],
  });

  const updateKeyword = (index: number, value: string) => {
    setFormValues((current) => {
      const nextItems = [...current.keywords];
      nextItems[index] = value;
      return { ...current, keywords: nextItems };
    });
  };

  const addKeyword = () => {
    setFormValues((current) => ({
      ...current,
      keywords: [...current.keywords, ""],
    }));
  };

  const removeKeyword = (index: number) => {
    setFormValues((current) => {
      const nextItems = [...current.keywords];
      nextItems.splice(index, 1);
      if (nextItems.length === 0) nextItems.push("");
      return { ...current, keywords: nextItems };
    });
  };

  const openCreate = () => {
    setEditingInjury(null);
    setFormValues(
      createEmptyFormValues(availableCategoriesForCreate[0]?.id || ""),
    );
    setActionError(null);
    setIsModalOpen(true);
  };

  const openEdit = (row: Injury) => {
    setEditingInjury(row);
    setFormValues({
      id: row.id,
      title: row.title ?? "",
      categoryId: row.categoryId ?? "",
      severity: row.severity ?? "",
      keywords: normalizeArray(row.keywords),
    });
    setActionError(null);
    setIsModalOpen(true);
  };

  const closeModal = () => {
    if (isSaving) return;
    setIsModalOpen(false);
    setEditingInjury(null);
    setFormValues(
      createEmptyFormValues(availableCategoriesForCreate[0]?.id || ""),
    );
    setActionError(null);
  };

  const normalizeList = (items: string[]) =>
    items.map((item) => item.trim()).filter(Boolean);

  const refreshAfterMutation = async () => {
    const [injuryData, categoryData] = await Promise.all([
      getInjuries({ forceRefresh: true }),
      getCategories(),
    ]);
    const guideData = (await getGuides()) as Array<{ injuryId?: string }>;
    setInjuries(injuryData);
    setCategories(categoryData);
    setGuideCounts(
      guideData.reduce<Record<string, number>>((acc, guide) => {
        const key = guide.injuryId || "";
        if (!key) return acc;
        acc[key] = (acc[key] || 0) + 1;
        return acc;
      }, {}),
    );
  };

  const handleSave = async () => {
    const id = formValues.id.trim();
    const title = formValues.title.trim();
    const categoryId = formValues.categoryId.trim();
    const keywords = normalizeList(formValues.keywords);

    if (!id) {
      setActionError("Document ID is required");
      return;
    }
    if (!title) {
      setActionError("Title is required");
      return;
    }
    if (!categoryId) {
      setActionError("Category is required");
      return;
    }

    const categoryCount = injuryCountByCategory[categoryId] || 0;
    const isChangingCategory =
      editingInjury && editingInjury.categoryId !== categoryId;
    const adjustedCount = isChangingCategory
      ? categoryCount
      : categoryCount - 1;

    if (adjustedCount >= 2) {
      setActionError(
        "Each category can have at most 2 injuries. Please pick another category.",
      );
      return;
    }

    setIsSaving(true);
    setActionError(null);

    try {
      if (editingInjury) {
        await updateInjury(editingInjury.id, {
          title,
          categoryId,
          severity: formValues.severity.trim() || undefined,
          keywords: keywords.length ? keywords : undefined,
        });
      } else {
        await createInjury(id, {
          title,
          categoryId,
          severity: formValues.severity.trim() || undefined,
          keywords: keywords.length ? keywords : undefined,
        });
      }

      await refreshAfterMutation();
      closeModal();
    } catch (err) {
      setActionError(
        err instanceof Error ? err.message : "Failed to save injury",
      );
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async (row: Injury) => {
    const confirmed = window.confirm(
      `Delete injury "${row.title}"? This cannot be undone.`,
    );
    if (!confirmed) return;

    setIsSaving(true);
    setActionError(null);

    try {
      await deleteInjury(row.id);
      await refreshAfterMutation();
      setExpandedId((current) => (current === row.id ? null : current));
    } catch (err) {
      setActionError(
        err instanceof Error ? err.message : "Failed to delete injury",
      );
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 rounded-2xl border bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
            Injuries
          </p>
          <h1 className="mt-2 text-2xl font-semibold">Injury catalog</h1>
          <p className="mt-1 text-sm text-slate-500">
            Every injury belongs to a category for guide linking.
          </p>
        </div>
        <div className="flex w-full flex-col gap-3 sm:w-auto sm:flex-row sm:items-center">
          <div className="flex w-full items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600 sm:w-72">
            <Search className="h-4 w-4" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search injuries"
              className="w-full bg-transparent outline-none"
            />
          </div>
          <Button className="rounded-xl" onClick={openCreate}>
            Add New
          </Button>
        </div>
      </div>

      {showSkeleton && (
        <div className="space-y-3 rounded-2xl border bg-white p-6 shadow-sm">
          <div className="h-4 w-44 animate-pulse rounded-full bg-slate-100" />
          <div className="grid gap-3">
            {Array.from({ length: 4 }).map((_, index) => (
              <div
                key={`injury-skeleton-${index}`}
                className="h-10 animate-pulse rounded-xl bg-slate-100"
              />
            ))}
          </div>
        </div>
      )}
      {error && <p className="text-sm text-red-600">{error}</p>}
      {actionError && <p className="text-sm text-red-600">{actionError}</p>}

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
            { key: "title", header: "Injury", className: "font-medium" },
            {
              key: "categoryId",
              header: "Category",
              render: (row) =>
                categoryNameById[row.categoryId] || row.categoryId,
            },
            {
              key: "guides",
              header: "Guides",
              render: (row) => guideCounts[row.id] || 0,
            },
            { key: "severity", header: "Severity" },
            {
              key: "keywords",
              header: "Keywords",
              render: (row) => row.keywords?.join(", ") || "-",
            },
            {
              key: "actions",
              header: "Actions",
              className: "text-right",
              render: (row) => (
                <div
                  className="flex justify-end gap-2"
                  onClick={(event) => event.stopPropagation()}
                >
                  <Button
                    variant="outline"
                    className="h-8 rounded-lg px-3"
                    onClick={() => openEdit(row)}
                  >
                    Edit
                  </Button>
                  <Button
                    variant="destructive"
                    className="h-8 rounded-lg px-3"
                    onClick={() => handleDelete(row)}
                  >
                    Delete
                  </Button>
                </div>
              ),
            },
          ]}
          data={filteredInjuries}
          getRowId={(row) => row.id}
          onRowClick={(row) =>
            setExpandedId((current) => (current === row.id ? null : row.id))
          }
          expandedRowId={expandedId}
          renderExpandedRow={(row) => (
            <div className="max-h-90 overflow-auto rounded-xl border border-slate-200 bg-white p-4 text-sm text-slate-600">
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Title
                  </p>
                  <p className="mt-1 wrap-break-word text-slate-900">
                    {row.title}
                  </p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Category
                  </p>
                  <p className="mt-1 wrap-break-word text-slate-900">
                    {categoryNameById[row.categoryId] || row.categoryId}
                  </p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Guides
                  </p>
                  <p className="mt-1 text-slate-900">
                    {guideCounts[row.id] || 0}
                  </p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Severity
                  </p>
                  <p className="mt-1 text-slate-900">{row.severity || "-"}</p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Keywords
                  </p>
                  {renderList(row.keywords)}
                </div>
                <div className="sm:col-span-2">
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Document ID
                  </p>
                  <p className="mt-1 wrap-break-word text-slate-900">
                    {row.id}
                  </p>
                </div>
              </div>
            </div>
          )}
        />
      )}

      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/40 px-4">
          <div className="w-full max-w-xl rounded-2xl bg-white p-6 shadow-xl">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  {editingInjury ? "Edit injury" : "New injury"}
                </p>
                <h2 className="mt-2 text-xl font-semibold text-slate-900">
                  {editingInjury ? "Update injury" : "Create injury"}
                </h2>
              </div>
              <button
                type="button"
                onClick={closeModal}
                className="rounded-lg px-2 py-1 text-sm text-slate-500 hover:bg-slate-100"
                disabled={isSaving}
              >
                Close
              </button>
            </div>

            <div className="mt-5 space-y-4">
              <div>
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Document ID
                </label>
                <input
                  value={formValues.id}
                  onChange={(event) =>
                    setFormValues((current) => ({
                      ...current,
                      id: event.target.value,
                    }))
                  }
                  className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                  placeholder="bleeding_minor"
                  disabled={Boolean(editingInjury)}
                />
                <p className="mt-2 text-xs text-slate-500">
                  Use a stable ID like "bleeding_minor".
                </p>
              </div>
              <div>
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Title
                </label>
                <input
                  value={formValues.title}
                  onChange={(event) =>
                    setFormValues((current) => ({
                      ...current,
                      title: event.target.value,
                    }))
                  }
                  className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                  placeholder="Minor bleeding"
                />
              </div>
              <div>
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Category
                </label>
                <select
                  value={formValues.categoryId}
                  onChange={(event) =>
                    setFormValues((current) => ({
                      ...current,
                      categoryId: event.target.value,
                    }))
                  }
                  className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                >
                  {!editingInjury &&
                    availableCategoriesForCreate.length === 0 && (
                      <option value="" disabled>
                        No categories without injuries
                      </option>
                    )}
                  {!editingInjury &&
                    availableCategoriesForCreate.map((category) => (
                      <option key={category.id} value={category.id}>
                        {category.name}
                      </option>
                    ))}
                  {editingInjury &&
                    categories.map((category) => {
                      const count = injuryCountByCategory[category.id] || 0;
                      const isCurrent =
                        category.id === editingInjury.categoryId;
                      const isFull = count >= 2 && !isCurrent;
                      return (
                        <option
                          key={category.id}
                          value={category.id}
                          disabled={isFull}
                        >
                          {category.name}
                        </option>
                      );
                    })}
                </select>
              </div>
              <div>
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Severity
                </label>
                <input
                  value={formValues.severity}
                  onChange={(event) =>
                    setFormValues((current) => ({
                      ...current,
                      severity: event.target.value,
                    }))
                  }
                  className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                  placeholder="minor"
                />
              </div>
              <div>
                <div className="flex items-center justify-between">
                  <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                    Keywords
                  </label>
                  <button
                    type="button"
                    onClick={addKeyword}
                    className="text-xs text-slate-500 hover:text-slate-900"
                  >
                    + Add
                  </button>
                </div>
                {formValues.keywords.map((value, index) => (
                  <div
                    key={`keywords-${index}`}
                    className="mt-2 flex items-center gap-2"
                  >
                    <input
                      value={value}
                      onChange={(event) =>
                        updateKeyword(index, event.target.value)
                      }
                      className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                      placeholder="Ex: bleeding"
                    />
                    <button
                      type="button"
                      onClick={() => removeKeyword(index)}
                      className="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500 hover:bg-slate-50"
                      disabled={formValues.keywords.length <= 1}
                    >
                      Remove
                    </button>
                  </div>
                ))}
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-3">
              <Button
                variant="outline"
                disabled={isSaving}
                onClick={closeModal}
              >
                Cancel
              </Button>
              <Button onClick={handleSave} disabled={isSaving}>
                {isSaving ? "Saving..." : "Save"}
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
