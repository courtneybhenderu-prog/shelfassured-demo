import { useEffect, useState } from "react";
import { createClient } from "@supabase/supabase-js";

const supabase = createClient(import.meta.env.VITE_SUPABASE_URL!, import.meta.env.VITE_SUPABASE_ANON_KEY!);

export default function AdminBrandDetail() {
  const id = location.pathname.split("/").pop()!;
  const [row, setRow] = useState<any>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    supabase.from("brands").select("*").eq("id", id).single().then(({ data, error }) => {
      if (error) console.error(error);
      setRow(data);
      setLoading(false);
    });
  }, [id]);

  if (loading) return <div className="p-6">Loading...</div>;
  if (!row) return <div className="p-6">Brand not found</div>;

  return (
    <div className="p-6">
      <h1 className="text-2xl">{row.name}</h1>
      <div className="mt-3 text-sm text-gray-600">{row.website}</div>
      <div className="mt-2 text-sm text-gray-600">{row.primary_email}</div>
      
      {/* Admin-only fields */}
      <div className="mt-4 p-4 bg-gray-50 rounded-lg">
        <h3 className="font-medium text-sm text-gray-700">Admin Fields</h3>
        <div className="mt-2 text-sm">
          <p>Broker: {row.broker_name || '—'}</p>
          <p>NDA: {row.nda_status || '—'}</p>
          <p>Data Source: {row.data_source || '—'}</p>
        </div>
      </div>

      <pre className="mt-4 text-xs bg-gray-50 p-3 rounded-xl overflow-auto">{JSON.stringify(row, null, 2)}</pre>
    </div>
  );
}

