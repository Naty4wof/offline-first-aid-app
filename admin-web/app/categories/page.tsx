"use client";

import { useEffect, useMemo, useState } from "react";
import { ChevronDown, ChevronRight, Search } from "lucide-react";

import DataTable from "@/components/data-table";
import { Button } from "@/components/ui/button";
import {
  createCategory,
  deleteCategory,
  getCategories,
  updateCategory,
  type Category,
} from "@/lib/firestore/categories";

export default function CategoriesPage() {
  const [query, setQuery] = useState("");
  const [categories, setCategories] = useState<Category[]>([]);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [formValues, setFormValues] = useState({
    id: "",
    name: "",
    description: "",
  });
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    let isMounted = true;

    const refreshCategories = async () => {
      const data = await getCategories();
      if (isMounted) setCategories(data);
    };

    const loadCategories = async () => {
      try {
        await refreshCategories();
        if (isMounted) setExpandedId(null);
      } catch (err) {
        if (isMounted) {
          setError(
            err instanceof Error ? err.message : "Failed to load categories",
          );
        }
      } finally {
        if (isMounted) setLoading(false);
      }
    };

    loadCategories();

    return () => {
      isMounted = false;
    };
  }, []);

  const handleOpenCreate = () => {
    setEditingCategory(null);
    setFormValues({ id: "", name: "", description: "" });
    setActionError(null);
    setIsModalOpen(true);
  };

  const handleOpenEdit = (category: Category) => {
    setEditingCategory(category);
    setFormValues({
      id: category.id ?? "",
      name: category.name ?? "",
      description: category.description ?? "",
    });
    setActionError(null);
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    if (isSaving) return;
    setIsModalOpen(false);
    setEditingCategory(null);
    setFormValues({ id: "", name: "", description: "" });
    setActionError(null);
  };

  const handleSave = async () => {
    const id = formValues.id.trim();
    const name = formValues.name.trim();
    if (!id) {
      setActionError("Document ID is required");
      return;
    }
    if (!name) {
      setActionError("Name is required");
      return;
    }

    setIsSaving(true);
    setActionError(null);

    try {
      if (editingCategory) {
        await updateCategory(editingCategory.id, {
          name,
          description: formValues.description.trim() || undefined,
        });
      } else {
        await createCategory(id, {
          name,
          description: formValues.description.trim() || undefined,
        });
      }

      const data = await getCategories({ forceRefresh: true });
      setCategories(data);
      setIsModalOpen(false);
      setEditingCategory(null);
      setFormValues({ id: "", name: "", description: "" });
    } catch (err) {
      setActionError(
        err instanceof Error ? err.message : "Failed to save category",
      );
    } finally {
      setIsSaving(false);
    }
  };

  const handleDelete = async (category: Category) => {
    const confirmed = window.confirm(
      `Delete category "${category.name}"? This cannot be undone.`,
    );
    if (!confirmed) return;

    setIsSaving(true);
    setActionError(null);

    try {
      await deleteCategory(category.id);
      const data = await getCategories({ forceRefresh: true });
      setCategories(data);
      setExpandedId((current) => (current === category.id ? null : current));
    } catch (err) {
      setActionError(
        err instanceof Error ? err.message : "Failed to delete category",
      );
    } finally {
      setIsSaving(false);
    }
  };

  const filteredCategories = useMemo(() => {
    if (!query) return categories;
    const lower = query.toLowerCase();
    return categories.filter((category) =>
      category.name.toLowerCase().includes(lower),
    );
  }, [query, categories]);

  const showSkeleton = loading && !error;

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 rounded-2xl border bg-white p-6 shadow-sm sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
            Categories
          </p>
          <h1 className="mt-2 text-2xl font-semibold">Injury categories</h1>
          <p className="mt-1 text-sm text-slate-500">
            Categories group injuries for structured guide management.
          </p>
        </div>
        <div className="flex w-full flex-col gap-3 sm:w-auto sm:flex-row sm:items-center">
          <div className="flex w-full items-center gap-2 rounded-xl border border-slate-200 bg-slate-50 px-3 py-2 text-sm text-slate-600 sm:w-72">
            <Search className="h-4 w-4" />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="Search categories"
              className="w-full bg-transparent outline-none"
            />
          </div>
          <Button className="rounded-xl" onClick={handleOpenCreate}>
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
                key={`category-skeleton-${index}`}
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
            { key: "name", header: "Category", className: "font-medium" },
            { key: "description", header: "Description" },
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
                    onClick={() => handleOpenEdit(row)}
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
          data={filteredCategories}
          getRowId={(row) => row.id}
          onRowClick={(row) =>
            setExpandedId((current) => (current === row.id ? null : row.id))
          }
          expandedRowId={expandedId}
          renderExpandedRow={(row) => (
            <div className="max-h-[280px] overflow-auto rounded-xl border border-slate-200 bg-white p-4 text-sm text-slate-600">
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Name
                  </p>
                  <p className="mt-1 break-words text-slate-900">{row.name}</p>
                </div>
                <div>
                  <p className="text-xs uppercase tracking-[0.18em] text-slate-400">
                    Description
                  </p>
                  <p className="mt-1 whitespace-pre-wrap break-words text-slate-900">
                    {row.description || "-"}
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

      {isModalOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/40 px-4">
          <div className="w-full max-w-lg rounded-2xl bg-white p-6 shadow-xl">
            <div className="flex items-start justify-between">
              <div>
                <p className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  {editingCategory ? "Edit category" : "New category"}
                </p>
                <h2 className="mt-2 text-xl font-semibold text-slate-900">
                  {editingCategory ? "Update category" : "Create category"}
                </h2>
              </div>
              <button
                type="button"
                onClick={handleCloseModal}
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
                  placeholder="bleeding"
                  disabled={Boolean(editingCategory)}
                />
                <p className="mt-2 text-xs text-slate-500">
                  Use a stable ID like "bleeding" or "burns".
                </p>
              </div>
              <div>
                <label className="text-xs uppercase tracking-[0.2em] text-slate-500">
                  Name
                </label>
                <input
                  value={formValues.name}
                  onChange={(event) =>
                    setFormValues((current) => ({
                      ...current,
                      name: event.target.value,
                    }))
                  }
                  className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                  placeholder="Category name"
                />
              </div>
              <div>
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
                  rows={4}
                  className="mt-2 w-full rounded-xl border border-slate-200 px-3 py-2 text-sm text-slate-900 outline-none focus:border-slate-400"
                  placeholder="Short description"
                />
              </div>
            </div>

            <div className="mt-6 flex items-center justify-end gap-3">
              <Button
                variant="outline"
                onClick={handleCloseModal}
                disabled={isSaving}
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
