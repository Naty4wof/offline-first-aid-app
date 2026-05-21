import { Fragment, ReactNode } from "react";

import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";

type Column<T> = {
  key: keyof T | string;
  header: string;
  className?: string;
  render?: (row: T) => ReactNode;
};

type DataTableProps<T> = {
  columns: Array<Column<T>>;
  data: T[];
  emptyState?: string;
  onRowClick?: (row: T) => void;
  getRowId?: (row: T, index: number) => string;
  expandedRowId?: string | null;
  renderExpandedRow?: (row: T) => ReactNode;
};

export default function DataTable<T>({
  columns,
  data,
  emptyState = "No records found",
  onRowClick,
  getRowId,
  expandedRowId,
  renderExpandedRow,
}: DataTableProps<T>) {
  return (
    <div className="overflow-hidden rounded-2xl border bg-white shadow-sm">
      <Table>
        <TableHeader className="bg-slate-50">
          <TableRow>
            {columns.map((column) => (
              <TableHead key={String(column.key)} className={column.className}>
                {column.header}
              </TableHead>
            ))}
          </TableRow>
        </TableHeader>
        <TableBody>
          {data.length === 0 ? (
            <TableRow>
              <TableCell
                colSpan={columns.length}
                className="py-6 text-center text-sm text-slate-500"
              >
                {emptyState}
              </TableCell>
            </TableRow>
          ) : (
            data.map((row, index) => {
              const rowId = getRowId ? getRowId(row, index) : String(index);
              const isExpanded = expandedRowId && rowId === expandedRowId;

              return (
                <Fragment key={rowId}>
                  <TableRow
                    key={rowId}
                    onClick={onRowClick ? () => onRowClick(row) : undefined}
                    className={
                      onRowClick
                        ? "cursor-pointer hover:bg-slate-50"
                        : undefined
                    }
                  >
                    {columns.map((column) => (
                      <TableCell
                        key={String(column.key)}
                        className={column.className}
                      >
                        {column.render
                          ? column.render(row)
                          : String(
                              (row as Record<string, unknown>)[
                                String(column.key)
                              ],
                            )}
                      </TableCell>
                    ))}
                  </TableRow>
                  {isExpanded && renderExpandedRow && (
                    <TableRow key={`${rowId}-expanded`}>
                      <TableCell
                        colSpan={columns.length}
                        className="bg-slate-50"
                      >
                        {renderExpandedRow(row)}
                      </TableCell>
                    </TableRow>
                  )}
                </Fragment>
              );
            })
          )}
        </TableBody>
      </Table>
    </div>
  );
}
