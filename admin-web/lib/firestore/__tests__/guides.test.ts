import { vi, describe, it, expect } from "vitest";
import { getGuides, createGuide, updateGuide, deleteGuide } from "../guides";

// Mock Firebase
vi.mock("../../firebase", () => ({
  db: {},
}));

vi.mock("firebase/firestore", () => ({
  collection: vi.fn(),
  getDocs: vi.fn(() =>
    Promise.resolve({
      docs: [
        { id: "1", data: () => ({ title: "Test Guide", injuryId: "i1" }) },
      ],
    }),
  ),
  doc: vi.fn(),
  setDoc: vi.fn(() => Promise.resolve()),
  updateDoc: vi.fn(() => Promise.resolve()),
  deleteDoc: vi.fn(() => Promise.resolve()),
}));

describe("Guides Firestore Service", () => {
  it("should fetch guides", async () => {
    const guides = await getGuides({ forceRefresh: true });
    expect(guides).toHaveLength(1);
    expect(guides[0].title).toBe("Test Guide");
  });

  it("should create a guide", async () => {
    await expect(
      createGuide("new-id", { title: "New" }),
    ).resolves.not.toThrow();
  });

  it("should update a guide", async () => {
    await expect(updateGuide("1", { title: "Updated" })).resolves.not.toThrow();
  });

  it("should delete a guide", async () => {
    await expect(deleteGuide("1")).resolves.not.toThrow();
  });
});
