import React, { useState } from "react";
import { createClient } from "@supabase/supabase-js";

/**
 * STEP 1: Admin Brand Creation Page
 * Route: /admin/brands/new
 * Scope: Admin-only brand onboarding (public + admin-only fields)
 * - Public fields are persisted via RPC: upsert_brand_public
 * - Admin-only fields are updated directly on brands table *after* RPC returns the brand id
 * - Minimal validation: brand name required
 * - Nice-to-have: inline status + redirect link to the new brand detail page
 *
 * ENV required (Cursor: set in .env.local and expose as VITE_*)
 *   VITE_SUPABASE_URL
 *   VITE_SUPABASE_ANON_KEY
 */

// Single Supabase browser client (swap for your shared client if you already have one)
const supabase = createClient(
  import.meta.env.VITE_SUPABASE_URL as string,
  import.meta.env.VITE_SUPABASE_ANON_KEY as string
);

// Types for form values
type PublicFields = {
  name: string;
  website?: string;
  primary_email?: string;
  phone?: string;
  address?: string;
};

type AdminOnlyFields = {
  broker_name?: string;
  broker_agreement?: string; // plain text or URL reference for now
  nda_status?: string; // e.g., "none" | "sent" | "signed"
  internal_notes?: string;
};

export default function AdminNewBrandPage() {
  const [publicValues, setPublicValues] = useState<PublicFields>({ name: "" });
  const [adminValues, setAdminValues] = useState<AdminOnlyFields>({});
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [brandId, setBrandId] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);

    // basic guard
    if (!publicValues.name?.trim()) {
      setError("Brand name is required.");
      return;
    }

    setSubmitting(true);
    let newId: string | null = null;

    try {
      // 1) Save public fields via RPC (protects admin-only fields)
      const { data: upsertId, error: rpcErr } = await supabase.rpc("upsert_brand_public", {
        p_id: null, // creating new
        p_name: publicValues.name,
        p_website: publicValues.website ?? null,
        p_primary_email: publicValues.primary_email ?? null,
        p_phone: publicValues.phone ?? null,
        p_address: publicValues.address ?? null,
      });
      if (rpcErr) throw rpcErr;
      newId = upsertId as string;
      setBrandId(newId);

      // 2) If admin-only fields provided, update brand directly
      const adminPatch: Record<string, any> = {};
      if (adminValues.broker_name) adminPatch.broker_name = adminValues.broker_name;
      if (adminValues.broker_agreement) adminPatch.broker_agreement = adminValues.broker_agreement;
      if (adminValues.nda_status) adminPatch.nda_status = adminValues.nda_status;
      if (adminValues.internal_notes) adminPatch.internal_notes = adminValues.internal_notes;

      if (Object.keys(adminPatch).length > 0) {
        const { error: updErr } = await supabase
          .from("brands")
          .update(adminPatch)
          .eq("id", newId!);
        if (updErr) throw updErr;
      }
    } catch (err: any) {
      console.error(err);
      setError(err?.message ?? "Something went wrong creating the brand.");
      setSubmitting(false);
      return;
    }

    setSubmitting(false);
  }

  return (
    <div className="mx-auto max-w-3xl p-6">
      <h1 className="text-2xl font-semibold">New Brand (Admin)</h1>
      <p className="text-sm text-gray-600 mt-1">
        Step 1 of onboarding. Public fields are saved via RPC. Admin-only fields are private and updated after create.
      </p>

      <form onSubmit={handleSubmit} className="mt-6 grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Public Fields */}
        <section className="md:col-span-2">
          <h2 className="text-lg font-medium">Public Fields</h2>
          <p className="text-xs text-gray-500">Visible to the brand later. Stored via <code>upsert_brand_public</code>.</p>
        </section>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-medium">Brand Name *</label>
          <input
            className="rounded-xl border p-2"
            placeholder="e.g., DJ's Boudain"
            value={publicValues.name}
            onChange={(e) => setPublicValues({ ...publicValues, name: e.target.value })}
            required
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-medium">Website</label>
          <input
            className="rounded-xl border p-2"
            placeholder="https://example.com"
            value={publicValues.website ?? ""}
            onChange={(e) => setPublicValues({ ...publicValues, website: e.target.value })}
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-medium">Primary Email</label>
          <input
            className="rounded-xl border p-2"
            placeholder="contact@example.com"
            value={publicValues.primary_email ?? ""}
            onChange={(e) => setPublicValues({ ...publicValues, primary_email: e.target.value })}
            type="email"
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-medium">Phone</label>
          <input
            className="rounded-xl border p-2"
            placeholder="(555) 555-5555"
            value={publicValues.phone ?? ""}
            onChange={(e) => setPublicValues({ ...publicValues, phone: e.target.value })}
          />
        </div>

        <div className="md:col-span-2 flex flex-col gap-2">
          <label className="text-sm font-medium">Address</label>
          <input
            className="rounded-xl border p-2"
            placeholder="Street, City, State, ZIP"
            value={publicValues.address ?? ""}
            onChange={(e) => setPublicValues({ ...publicValues, address: e.target.value })}
          />
        </div>

        {/* Admin-only Fields */}
        <section className="md:col-span-2 pt-2">
          <h2 className="text-lg font-medium">Admin-only Fields</h2>
          <p className="text-xs text-gray-500">Hidden from brands. Patched directly on the <code>brands</code> table after create.</p>
        </section>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-medium">Broker Name (private)</label>
          <input
            className="rounded-xl border p-2"
            placeholder="e.g., Mana Foods"
            value={adminValues.broker_name ?? ""}
            onChange={(e) => setAdminValues({ ...adminValues, broker_name: e.target.value })}
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-medium">Broker Agreement (private)</label>
          <input
            className="rounded-xl border p-2"
            placeholder="Notes or a document URL"
            value={adminValues.broker_agreement ?? ""}
            onChange={(e) => setAdminValues({ ...adminValues, broker_agreement: e.target.value })}
          />
        </div>

        <div className="flex flex-col gap-2">
          <label className="text-sm font-medium">NDA Status (private)</label>
          <input
            className="rounded-xl border p-2"
            placeholder="none | sent | signed"
            value={adminValues.nda_status ?? ""}
            onChange={(e) => setAdminValues({ ...adminValues, nda_status: e.target.value })}
          />
        </div>

        <div className="md:col-span-2 flex flex-col gap-2">
          <label className="text-sm font-medium">Internal Notes (private)</label>
          <textarea
            className="rounded-xl border p-2 min-h-[96px]"
            placeholder="Background, relationship context, data sources, etc."
            value={adminValues.internal_notes ?? ""}
            onChange={(e) => setAdminValues({ ...adminValues, internal_notes: e.target.value })}
          />
        </div>

        {/* Actions */}
        <div className="md:col-span-2 flex items-center gap-3 pt-2">
          <button
            type="submit"
            disabled={submitting}
            className="px-4 py-2 rounded-xl bg-black text-white disabled:opacity-60"
          >
            {submitting ? "Saving…" : "Save Brand"}
          </button>

          {error && <span className="text-red-600 text-sm">{error}</span>}
          {brandId && !error && (
            <a
              href={`/admin/brands/${brandId}`}
              className="text-sm underline text-blue-700"
            >
              View brand →
            </a>
          )}
        </div>
      </form>

      {/* Dev helper panel */}
      <div className="mt-8 grid grid-cols-1 md:grid-cols-2 gap-6">
        <div className="rounded-2xl border p-4">
          <h3 className="font-medium mb-2">Payload (public via RPC)</h3>
          <pre className="text-xs whitespace-pre-wrap">{JSON.stringify(publicValues, null, 2)}</pre>
        </div>
        <div className="rounded-2xl border p-4">
          <h3 className="font-medium mb-2">Patch (admin-only)</h3>
          <pre className="text-xs whitespace-pre-wrap">{JSON.stringify(adminValues, null, 2)}</pre>
        </div>
      </div>
    </div>
  );
}

