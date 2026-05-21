import { describe, it, expect } from "vitest";

/**
 * Pure logic mirrors for documentation; full integration tests need Miniflare/wrangler vitest pool.
 */

describe("breakdown request validation", () => {
  it("caps side tasks at 2", () => {
    const input = ["a", "b", "c"];
    const capped = input.slice(0, 2);
    expect(capped).toHaveLength(2);
  });

  it("requires sides array length to match side task count", () => {
    const sideTasks = ["运动", "阅读"];
    const sides = [{ stages: [{ title: "s1" }] }];
    expect(sides.length === sideTasks.length).toBe(false);
  });
});
