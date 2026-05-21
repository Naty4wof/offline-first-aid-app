"use client";

import { useEffect, useMemo, useState } from "react";
import { ArrowLeft, ChevronDown, ChevronRight, Search } from "lucide-react";

import DataTable from "@/components/data-table";
import { Button } from "@/components/ui/button";
import {
  createGuide,
  deleteGuide,
  getGuides,
  updateGuide,
} from "@/lib/firestore/guides";
import { getInjuries, type Injury } from "@/lib/firestore/injuries";
import { getCategories, type Category } from "@/lib/firestore/categories";

type Guide = {
  id: string;
  injuryId: string;
  title: string;
  description?: string;
  symptoms?: string[];
  steps?: string[];
  warnings?: string[];
  whenToSeekHelp?: string[];
  explanation?: string;
  dos?: string[];
  donts?: string[];
  imagePath?: string;
  audioPath?: string;
  updatedAt?: { toDate?: () => Date } | string;
};

type GuideFormValues = {
  id: string;
  injuryId: string;
  title: string;
  description: string;
  symptoms: string[];
  steps: string[];
  warnings: string[];
  whenToSeekHelp: string[];
  explanation: string;
  dos: string[];
  donts: string[];
  imagePath: string;
  audioPath: string;
};

type GuideListField =
  | "symptoms"
  | "steps"
  | "warnings"
  | "whenToSeekHelp"
  | "dos"
  | "donts";

function formatUpdatedAt(value?: Guide["updatedAt"]) {
  if (!value) return "-";
  if (typeof value === "string") return value;
  if (typeof value.toDate === "function") {
    return value.toDate().toLocaleDateString();
  }
  return "-";
}

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

export default function GuidesPage() {
  const [query, setQuery] = useState("");
  const [guides, setGuides] = useState<Guide[]>([]);
  const [injuries, setInjuries] = useState<Injury[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [showForm, setShowForm] = useState(false);
  const [formValues, setFormValues] = useState<GuideFormValues>({
    id: "",
    injuryId: "",
    title: "",
    description: "",
    symptoms: [""],
    steps: [""],
    warnings: [""],
    whenToSeekHelp: [""],
    explanation: "",
    dos: [""],
    donts: [""],
    imagePath: "",
    audioPath: "",
  });
  const [editingGuide, setEditingGuide] = useState<Guide | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const loadGuides = async () => {
      try {
        const [guideData, injuryData, categoryData] = await Promise.all([
          getGuides(),
          getInjuries(),
          getCategories(),
        ]);
        if (isMounted) {
          setGuides(guideData as Guide[]);
          setInjuries(injuryData);
          setCategories(categoryData);
          setExpandedId(null);
        }
      } catch (err) {
        if (isMounted) {
          setError(
            err instanceof Error ? err.message : "Failed to load guides",
          );
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    loadGuides();

    return () => {
      isMounted = false;
    };
  }, []);

  const injuryById = useMemo(() => {
    return injuries.reduce<Record<string, Injury>>((acc, injury) => {
      acc[injury.id] = injury;
      return acc;
    }, {});
  }, [injuries]);

  const guideCountByInjury = useMemo(() => {
    return guides.reduce<Record<string, number>>((acc, guide) => {
      acc[guide.injuryId] = (acc[guide.injuryId] || 0) + 1;
      return acc;
    }, {});
  }, [guides]);

  const categoryNameById = useMemo(() => {
    return categories.reduce<Record<string, string>>((acc, category) => {
      acc[category.id] = category.name;
      return acc;
    }, {});
  }, [categories]);

  const injuriesByCategory = useMemo(() => {
    return injuries.reduce<Record<string, Injury[]>>((acc, injury) => {
      const guideCount = guideCountByInjury[injury.id] || 0;
      const isCurrent = editingGuide?.injuryId === injury.id;
      if (guideCount > 0 && !isCurrent) return acc;
      if (!acc[injury.categoryId]) acc[injury.categoryId] = [];
      acc[injury.categoryId].push(injury);
      return acc;
    }, {});
  }, [injuries, guideCountByInjury, editingGuide]);

  const hasEligibleInjury = useMemo(() => {
    return Object.values(injuriesByCategory).some((items) => items.length > 0);
  }, [injuriesByCategory]);

  const filteredGuides = useMemo(() => {
    if (!query) return guides;
    const lower = query.toLowerCase();
    return guides.filter((guide) =>
      [
        guide.title,
        guide.injuryId,
        injuryById[guide.injuryId]?.title,
        categoryNameById[injuryById[guide.injuryId]?.categoryId ?? ""],
        guide.description,
      ]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(lower)),
    );
  }, [query, guides, injuryById, categoryNameById]);

  const showSkeleton = loading && !error;

  const normalizeArray = (items?: string[]) =>
    items && items.length > 0 ? items : [""];

  const createEmptyFormValues = (injuryId: string): GuideFormValues => ({
    id: "",
    injuryId,
    title: "",
    description: "",
    symptoms: [""],
    steps: [""],
    warnings: [""],
    whenToSeekHelp: [""],
    explanation: "",
    dos: [""],
    donts: [""],
    imagePath: "",
    audioPath: "",
  });

  const updateListField = (
    field: GuideListField,
    index: number,
    value: string,
  ) => {
    setFormValues((current) => {
      const nextItems = [...current[field]];
      nextItems[index] = value;
      return { ...current, [field]: nextItems };
    });
  };

  const addListItem = (field: GuideListField) => {
    setFormValues((current) => ({
      ...current,
      [field]: [...current[field], ""],
    }));
  };

  const removeListItem = (field: GuideListField, index: number) => {
    setFormValues((current) => {
      const nextItems = [...current[field]];
      nextItems.splice(index, 1);
      if (nextItems.length === 0) nextItems.push("");
      return { ...current, [field]: nextItems };
    });
  };

  const openCreate = () => {
    setEditingGuide(null);
    const firstAvailable = categories
      .map((category) => injuriesByCategory[category.id]?.[0])
      .find(Boolean);
    setFormValues(createEmptyFormValues(firstAvailable?.id || ""));
    setActionError(null);
    setShowForm(true);
  };

  const openEdit = (guide: Guide) => {
    setEditingGuide(guide);
    setFormValues({
      id: guide.id,
      injuryId: guide.injuryId,
      title: guide.title ?? "",
      description: guide.description ?? "",
      symptoms: normalizeArray(guide.symptoms),
      steps: normalizeArray(guide.steps),
      warnings: normalizeArray(guide.warnings),
      whenToSeekHelp: normalizeArray(guide.whenToSeekHelp),
      explanation: guide.explanation ?? "",
      dos: normalizeArray(guide.dos),
      donts: normalizeArray(guide.donts),
      imagePath: guide.imagePath ?? "",
      audioPath: guide.audioPath ?? "",
    });
    setActionError(null);
    setShowForm(true);
  };

  const closeModal = () => {
    if (isSaving) return;
    setShowForm(false);
    setEditingGuide(null);
    const firstAvailable = categories
      .map((category) => injuriesByCategory[category.id]?.[0])
      .find(Boolean);
    setFormValues(createEmptyFormValues(firstAvailable?.id || ""));
    setActionError(null);
  };

  const normalizeList = (items: string[]) =>
    items.map((item) => item.trim()).filter(Boolean);

  const refreshAfterMutation = async () => {
    const [guideData, injuryData, categoryData] = await Promise.all([
      getGuides({ forceRefresh: true }),
      getInjuries(),
      getCategories(),
    ]);
    setGuides(guideData as Guide[]);
    setInjuries(injuryData);
    setCategories(categoryData);
  };

  const handleSave = async () => {
    const id = formValues.id.trim();
    const injuryId = formValues.injuryId.trim();
    const title = formValues.title.trim();

    if (!id) {
      setActionError("Document ID is required");
      return;
    }
    if (!injuryId) {
      setActionError("Injury is required");
      return;
    }
    if (!title) {
      setActionError("Title is required");
      return;
    }

    const payload = {
      injuryId,
      title,
      description: formValues.description.trim() || undefined,
      symptoms: normalizeList(formValues.symptoms),
      steps: normalizeList(formValues.steps),
      warnings: normalizeList(formValues.warnings),
      whenToSeekHelp: normalizeList(formValues.whenToSeekHelp),
      explanation: formValues.explanation.trim() || undefined,
      dos: normalizeList(formValues.dos),
      donts: normalizeList(formValues.donts),
      imagePath: formValues.imagePath.trim() || undefined,
      audioPath: formValues.audioPath.trim() || undefined,
    };

    setIsSaving(true);
    setActionError(null);

    try {
      if (editingGuide) {
        await updateGuide(editingGuide.id, payload);
      } else {
        await createGuide(id, payload);
      }

      await refreshAfterMutation();
      closeModal();
    } catch (err) {
      setActionError(
        err instanceof Error ? err.message : "Failed to save guide",
      );
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async (guide: Guide) => {
    const confirmed = window.confirm(
      `Delete guide "${guide.title}"? This cannot be undone.`,
    );
    if (!confirmed) return;

    setIsSaving(true);
    setActionError(null);

    try {
      await deleteGuide(guide.id);
      await refreshAfterMutation();
      setExpandedId((current) => (current === guide.id ? null : current));
    } catch (err) {
      setActionError(
        err instanceof Error ? err.message : "Failed to delete guide",
      );
    } finally {
      setIsSaving(false);
    }
  };

  return (
    <div className="space-y-6">
      {!showForm && (
        <>
          <div className="flex flex-col gap-4 rounded-2xl border bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
                Guides
              </p>
              <h1 className="mt-2 text-2xl font-semibold">Guide library</h1>
              <p className="mt-1 text-sm text-slate-500">
                Guides are linked to an injury and its parent category.
              </p>
            </div>
            <div className="flex w-full flex-col gap-3 sm:w-auto sm:flex-row sm:items-center">
              <div className="flex w-full items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600 sm:w-72">
                <Search className="h-4 w-4" />
                <input
                  value={query}
                  onChange={(event) => setQuery(event.target.value)}
                  placeholder="Search guides"
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
                    key={`guide-skeleton-${index}`}
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
                { key: "title", header: "Guide", className: "font-medium" },
                {
                  key: "injuryId",
                  header: "Injury",
                  render: (row) =>
                    injuryById[row.injuryId]?.title || row.injuryId,
                },
                {
                  key: "updatedAt",
                  header: "Updated",
                  render: (row) => formatUpdatedAt(row.updatedAt),
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
              data={filteredGuides}
              getRowId={(row) => row.id}
              onRowClick={(row) =>
                setExpandedId((current) => (current === row.id ? null : row.id))
              }
              expandedRowId={expandedId}
              renderExpandedRow={(row) => (
                <div className="max-h-105 overflow-auto rounded-xl border border-slate-200 bg-white p-4 text-sm text-slate-600">
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
                        Injury
                      </p>
                      <p className="mt-1 wrap-break-word text-slate-900">
                        {injuryById[row.injuryId]?.title || row.injuryId}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Category
                      </p>
                      <p className="mt-1 wrap-break-word text-slate-900">
                        {categoryNameById[
                          injuryById[row.injuryId]?.categoryId ?? ""
                        ] || "-"}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Updated
                      </p>
                      <p className="mt-1 text-slate-900">
                        {formatUpdatedAt(row.updatedAt)}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Description
                      </p>
                      <p className="mt-1 whitespace-pre-wrap wrap-break-word text-slate-900">
                        {row.description || "-"}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Symptoms
                      </p>
                      {renderList(row.symptoms)}
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Steps
                      </p>
                      {renderList(row.steps)}
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Warnings
                      </p>
                      {renderList(row.warnings)}
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        When To Seek Help
                      </p>
                      {renderList(row.whenToSeekHelp)}
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Explanation
                      </p>
                      <p className="mt-1 whitespace-pre-wrap wrap-break-word text-slate-900">
                        {row.explanation || "-"}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Dos
                      </p>
                      {renderList(row.dos)}
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Donts
                      </p>
                      {renderList(row.donts)}
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Image Path
                      </p>
                      <p className="mt-1 wrap-break-word text-slate-900">
                        {row.imagePath || "-"}
                      </p>
                    </div>
                    <div>
                      <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                        Audio Path
                      </p>
                      <p className="mt-1 wrap-break-word text-slate-900">
                        {row.audioPath || "-"}
                      </p>
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
        </>
      )}

      {showForm && (
        <div className="rounded-2xl border bg-white p-6 shadow-sm">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <button
                type="button"
                onClick={closeModal}
                className="inline-flex items-center gap-2 text-sm text-slate-500 hover:text-slate-900"
              >
                <ArrowLeft className="h-4 w-4" />
                Back to guides
              </button>
              <p className="mt-4 text-xs uppercase tracking-[0.2em] text-slate-500">
                {editingGuide ? "Edit guide" : "New guide"}
              </p>
              <h2 className="mt-2 text-xl font-semibold text-slate-900">
                {editingGuide ? "Update guide" : "Create guide"}
              </h2>
            </div>
            <div className="flex items-center gap-2">
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

          <div className="mt-6 grid gap-4 sm:grid-cols-2">
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
                placeholder="bleeding_minor_guide"
                disabled={Boolean(editingGuide)}
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                Injury
              </label>
              <select
                value={formValues.injuryId}
                onChange={(event) =>
                  setFormValues((current) => ({
                    ...current,
                    injuryId: event.target.value,
                  }))
                }
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
              >
                {!editingGuide && !hasEligibleInjury && (
                  <option value="" disabled>
                    All injuries already have guides
                  </option>
                )}
                {categories.map((category) => {
                  const options = injuriesByCategory[category.id] || [];
                  const filteredOptions = options.filter((injury) => {
                    const hasGuides = (guideCountByInjury[injury.id] || 0) > 0;
                    const isCurrent = editingGuide?.injuryId === injury.id;
                    return !hasGuides || isCurrent;
                  });
                  return (
                    <optgroup key={category.id} label={category.name}>
                      {filteredOptions.length === 0 ? (
                        <option value="" disabled>
                          No injuries without guides
                        </option>
                      ) : (
                        filteredOptions.map((injury) => (
                          <option key={injury.id} value={injury.id}>
                            {injury.title}
                          </option>
                        ))
                      )}
                    </optgroup>
                  );
                })}
              </select>
            </div>
            <div className="sm:col-span-2">
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
                placeholder="Treat minor bleeding"
              />
            </div>
            <div className="sm:col-span-2">
              <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                Description
              </label>
              <textarea
                value={formValues.description}
                onChange={(event) =>
                  setFormValues((current) => ({
                    ...current,
                    description: event.target.value,
                  }))
                }
                rows={3}
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
              />
            </div>
            <div>
              <div className="flex items-center justify-between">
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Symptoms
                </label>
                <button
                  type="button"
                  onClick={() => addListItem("symptoms")}
                  className="text-xs text-slate-500 hover:text-slate-900"
                >
                  + Add
                </button>
              </div>
              {formValues.symptoms.map((value, index) => (
                <div
                  key={`symptoms-${index}`}
                  className="mt-2 flex items-center gap-2"
                >
                  <input
                    value={value}
                    onChange={(event) =>
                      updateListField("symptoms", index, event.target.value)
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                    placeholder="Ex: dizziness"
                  />
                  <button
                    type="button"
                    onClick={() => removeListItem("symptoms", index)}
                    className="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500 hover:bg-slate-50"
                    disabled={formValues.symptoms.length <= 1}
                  >
                    Remove
                  </button>
                </div>
              ))}
            </div>
            <div>
              <div className="flex items-center justify-between">
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Steps
                </label>
                <button
                  type="button"
                  onClick={() => addListItem("steps")}
                  className="text-xs text-slate-500 hover:text-slate-900"
                >
                  + Add
                </button>
              </div>
              {formValues.steps.map((value, index) => (
                <div
                  key={`steps-${index}`}
                  className="mt-2 flex items-center gap-2"
                >
                  <input
                    value={value}
                    onChange={(event) =>
                      updateListField("steps", index, event.target.value)
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                    placeholder="Ex: Apply pressure"
                  />
                  <button
                    type="button"
                    onClick={() => removeListItem("steps", index)}
                    className="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500 hover:bg-slate-50"
                    disabled={formValues.steps.length <= 1}
                  >
                    Remove
                  </button>
                </div>
              ))}
            </div>
            <div>
              <div className="flex items-center justify-between">
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Warnings
                </label>
                <button
                  type="button"
                  onClick={() => addListItem("warnings")}
                  className="text-xs text-slate-500 hover:text-slate-900"
                >
                  + Add
                </button>
              </div>
              {formValues.warnings.map((value, index) => (
                <div
                  key={`warnings-${index}`}
                  className="mt-2 flex items-center gap-2"
                >
                  <input
                    value={value}
                    onChange={(event) =>
                      updateListField("warnings", index, event.target.value)
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                    placeholder="Ex: Do not remove embedded objects"
                  />
                  <button
                    type="button"
                    onClick={() => removeListItem("warnings", index)}
                    className="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500 hover:bg-slate-50"
                    disabled={formValues.warnings.length <= 1}
                  >
                    Remove
                  </button>
                </div>
              ))}
            </div>
            <div>
              <div className="flex items-center justify-between">
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  When To Seek Help
                </label>
                <button
                  type="button"
                  onClick={() => addListItem("whenToSeekHelp")}
                  className="text-xs text-slate-500 hover:text-slate-900"
                >
                  + Add
                </button>
              </div>
              {formValues.whenToSeekHelp.map((value, index) => (
                <div
                  key={`whenToSeekHelp-${index}`}
                  className="mt-2 flex items-center gap-2"
                >
                  <input
                    value={value}
                    onChange={(event) =>
                      updateListField(
                        "whenToSeekHelp",
                        index,
                        event.target.value,
                      )
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                    placeholder="Ex: Bleeding won't stop"
                  />
                  <button
                    type="button"
                    onClick={() => removeListItem("whenToSeekHelp", index)}
                    className="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500 hover:bg-slate-50"
                    disabled={formValues.whenToSeekHelp.length <= 1}
                  >
                    Remove
                  </button>
                </div>
              ))}
            </div>
            <div className="sm:col-span-2">
              <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                Explanation
              </label>
              <textarea
                value={formValues.explanation}
                onChange={(event) =>
                  setFormValues((current) => ({
                    ...current,
                    explanation: event.target.value,
                  }))
                }
                rows={3}
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
              />
            </div>
            <div>
              <div className="flex items-center justify-between">
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Dos
                </label>
                <button
                  type="button"
                  onClick={() => addListItem("dos")}
                  className="text-xs text-slate-500 hover:text-slate-900"
                >
                  + Add
                </button>
              </div>
              {formValues.dos.map((value, index) => (
                <div
                  key={`dos-${index}`}
                  className="mt-2 flex items-center gap-2"
                >
                  <input
                    value={value}
                    onChange={(event) =>
                      updateListField("dos", index, event.target.value)
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                    placeholder="Ex: Keep wound clean"
                  />
                  <button
                    type="button"
                    onClick={() => removeListItem("dos", index)}
                    className="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500 hover:bg-slate-50"
                    disabled={formValues.dos.length <= 1}
                  >
                    Remove
                  </button>
                </div>
              ))}
            </div>
            <div>
              <div className="flex items-center justify-between">
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Donts
                </label>
                <button
                  type="button"
                  onClick={() => addListItem("donts")}
                  className="text-xs text-slate-500 hover:text-slate-900"
                >
                  + Add
                </button>
              </div>
              {formValues.donts.map((value, index) => (
                <div
                  key={`donts-${index}`}
                  className="mt-2 flex items-center gap-2"
                >
                  <input
                    value={value}
                    onChange={(event) =>
                      updateListField("donts", index, event.target.value)
                    }
                    className="w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                    placeholder="Ex: Use dirty cloths"
                  />
                  <button
                    type="button"
                    onClick={() => removeListItem("donts", index)}
                    className="rounded-lg border border-slate-200 px-2 py-1 text-xs text-slate-500 hover:bg-slate-50"
                    disabled={formValues.donts.length <= 1}
                  >
                    Remove
                  </button>
                </div>
              ))}
            </div>
            <div>
              <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                Image Path
              </label>
              <input
                value={formValues.imagePath}
                onChange={(event) =>
                  setFormValues((current) => ({
                    ...current,
                    imagePath: event.target.value,
                  }))
                }
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
              />
            </div>
            <div>
              <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                Audio Path
              </label>
              <input
                value={formValues.audioPath}
                onChange={(event) =>
                  setFormValues((current) => ({
                    ...current,
                    audioPath: event.target.value,
                  }))
                }
                className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
              />
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
