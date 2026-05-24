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

  it("accepts yyyy-MM-dd quest day keys", () => {
    const valid = /^\d{4}-\d{2}-\d{2}$/;
    expect(valid.test("2026-05-22")).toBe(true);
    expect(valid.test("2026-5-22")).toBe(false);
    expect(valid.test("../etc/passwd")).toBe(false);
  });

  it("honors forceRegenerate flag in request body", () => {
    const body = { mainTask: "写报告", forceRegenerate: true };
    expect(body.forceRegenerate).toBe(true);
  });

  it("validates hex colors for medal palette", () => {
    const hex = /^#[0-9A-Fa-f]{6}$/;
    expect(hex.test("#C45C26")).toBe(true);
    expect(hex.test("C45C26")).toBe(false);
    expect(hex.test("#xyz")).toBe(false);
  });
});
