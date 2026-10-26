// Dompetektif · AI investigation report
//
// Runs with the caller's JWT, so all Supabase queries are filtered by RLS. It
// returns a shape that matches `InvestigationReport` on the client; the client
// persists the report through its normal offline-first outbox.
//
// Configure a free-tier, OpenAI-compatible AI endpoint with:
//   supabase secrets set AI_API_KEY=... AI_MODEL=... [AI_BASE_URL=...]
// Without a key the function returns a deterministic heuristic report instead
// of failing, which keeps the feature usable in local demos.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2.49.4";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Severity = "info" | "warning" | "critical";

interface CategoryRow {
  id: string;
  name: string;
  kind: string;
  color_hex: string | null;
}

interface WalletRow {
  id: string;
  name: string;
  currency: string | null;
  deleted_at: string | null;
}

interface TransactionRow {
  id: string;
  wallet_id: string;
  type: "expense" | "income" | "transfer" | string;
  amount_minor: number;
  currency: string;
  category_id: string | null;
  occurred_at: string;
  merchant: string | null;
  note: string | null;
}

interface BudgetRow {
  id: string;
  wallet_id: string | null;
  category_id: string;
  amount_minor: number;
  currency: string;
  month: string;
  alert_threshold: number;
}

interface Finding {
  title: string;
  detail: string;
  severity: Severity;
}

interface Anomaly {
  title: string;
  detail: string;
  transaction_id: string | null;
  amount_minor: number | null;
  currency: string | null;
  severity: Severity;
}

interface ReportPayload {
  headline: string;
  summary: string;
  findings: Finding[];
  anomalies: Anomaly[];
  recommendations: string[];
}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function error(message: string, status = 400): Response {
  return json({ error: message }, status);
}

function clampText(value: unknown, max: number): string {
  if (typeof value !== "string") return "";
  return value.trim().slice(0, max);
}

function toSeverity(value: unknown, fallback: Severity = "info"): Severity {
  return value === "critical" || value === "warning" || value === "info"
    ? value
    : fallback;
}

function currencyFractionDigits(currency: string): number {
  return currency.toUpperCase() === "IDR" ? 0 : 2;
}

function formatMoney(
  minor: number,
  currency: string,
  localeCode: string,
): string {
  const digits = currencyFractionDigits(currency);
  return new Intl.NumberFormat(localeCode === "en" ? "en-US" : "id-ID", {
    style: "currency",
    currency,
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(minor / Math.pow(10, digits));
}

function formatPercent(value: number, localeCode: string): string {
  return new Intl.NumberFormat(localeCode === "en" ? "en-US" : "id-ID", {
    style: "percent",
    maximumFractionDigits: 1,
  }).format(value);
}

function periodLabel(from: Date, to: Date, localeCode: string): string {
  const formatter = new Intl.DateTimeFormat(
    localeCode === "en" ? "en-GB" : "id-ID",
    { day: "numeric", month: "short", year: "numeric" },
  );
  return `${formatter.format(from)} – ${formatter.format(to)}`;
}

function monthStart(date: Date): string {
  return `${date.getUTCFullYear()}-${String(date.getUTCMonth() + 1).padStart(
    2,
    "0",
  )}-01`;
}

function roundRatio(value: number): number {
  return Math.round(value * 1000) / 1000;
}

function computeHeuristic(input: {
  localeCode: string;
  from: Date;
  to: Date;
  walletName: string | null;
  transactions: TransactionRow[];
  history: TransactionRow[];
  categories: Map<string, CategoryRow>;
  budgets: BudgetRow[];
}): ReportPayload {
  const {
    localeCode,
    from,
    to,
    walletName,
    transactions,
    history,
    categories,
    budgets,
  } = input;
  const isId = localeCode !== "en";
  const currency = transactions[0]?.currency ?? "IDR";

  let income = 0;
  let expense = 0;
  const byCategory = new Map<string, number>();
  for (const tx of transactions) {
    if (tx.type === "income") income += tx.amount_minor;
    if (tx.type === "expense") {
      expense += tx.amount_minor;
      if (tx.category_id) {
        byCategory.set(
          tx.category_id,
          (byCategory.get(tx.category_id) ?? 0) + tx.amount_minor,
        );
      }
    }
  }
  const net = income - expense;
  const totalExpense = expense;

  const topCategories = [...byCategory.entries()]
    .map(([id, amount]) => ({
      category: categories.get(id),
      amount,
      ratio: totalExpense === 0 ? 0 : amount / totalExpense,
    }))
    .filter((item) => item.category)
    .sort((a, b) => b.amount - a.amount);

  const top = topCategories[0];
  const biggest = transactions
    .filter((tx) => tx.type === "expense")
    .sort((a, b) => b.amount_minor - a.amount_minor)[0];

  const findings: Finding[] = [];
  if (top?.category) {
    findings.push({
      title: isId ? "Pusat pengeluaran" : "Spending hotspot",
      detail: isId
        ? `${top.category.name} menyerap ${formatPercent(top.ratio, localeCode)} dari pengeluaran periode ini (${formatMoney(top.amount, currency, localeCode)}).`
        : `${top.category.name} absorbed ${formatPercent(top.ratio, localeCode)} of this period's spending (${formatMoney(top.amount, currency, localeCode)}).`,
      severity: top.ratio >= 0.4 ? "warning" : "info",
    });
  }
  if (biggest) {
    findings.push({
      title: isId ? "Transaksi terbesar" : "Largest transaction",
      detail: `${biggest.merchant?.trim() || biggest.note?.trim() || (isId ? "Tanpa judul" : "Untitled")} – ${formatMoney(biggest.amount_minor, currency, localeCode)}.`,
      severity: "info",
    });
  }

  const budgetProgress = budgets
    .filter((budget) => categories.has(budget.category_id))
    .map((budget) => {
      let spent = 0;
      for (const tx of transactions) {
        if (
          tx.type !== "expense" ||
          tx.category_id !== budget.category_id
        ) {
          continue;
        }
        if (budget.wallet_id && tx.wallet_id !== budget.wallet_id) continue;
        spent += tx.amount_minor;
      }
      const ratio = budget.amount_minor <= 0 ? 1 : spent / budget.amount_minor;
      return { budget, spent, ratio };
    })
    .sort((a, b) => b.ratio - a.ratio);

  for (const item of budgetProgress.filter((entry) => entry.ratio >= 0.8).slice(0, 2)) {
    const category = categories.get(item.budget.category_id);
    if (!category) continue;
    findings.push({
      title: isId
        ? `Batas TKP: ${category.name}`
        : `Crime scene: ${category.name}`,
      detail: isId
        ? `Terpakai ${formatMoney(item.spent, currency, localeCode)} dari ${formatMoney(item.budget.amount_minor, currency, localeCode)} (${formatPercent(item.ratio, localeCode)}).`
        : `Used ${formatMoney(item.spent, currency, localeCode)} of ${formatMoney(item.budget.amount_minor, currency, localeCode)} (${formatPercent(item.ratio, localeCode)}).`,
      severity: item.ratio >= 1 ? "critical" : "warning",
    });
  }

  // Category-aware anomaly detection over the trailing 90 days.
  const historyByCategory = new Map<string, number[]>();
  const allHistory: number[] = [];
  for (const tx of history) {
    if (tx.type !== "expense") continue;
    allHistory.push(tx.amount_minor);
    if (tx.category_id) {
      const values = historyByCategory.get(tx.category_id) ?? [];
      values.push(tx.amount_minor);
      historyByCategory.set(tx.category_id, values);
    }
  }
  const allAverage = allHistory.length
    ? allHistory.reduce((sum, value) => sum + value, 0) / allHistory.length
    : 0;

  const anomalyModels: Anomaly[] = [];
  for (const tx of transactions) {
    if (tx.type !== "expense") continue;
    const category = tx.category_id ? categories.get(tx.category_id) : null;
    const values = tx.category_id ? historyByCategory.get(tx.category_id) : null;
    let deviation = 0;
    let kind: "category" | "unusual" | null = null;

    if (values && values.length >= 3) {
      const average = values.reduce((sum, value) => sum + value, 0) / values.length;
      if (average > 0) deviation = tx.amount_minor / average;
      if (deviation >= 2.5 && tx.amount_minor >= 100000) kind = "category";
    } else if (allAverage > 0) {
      deviation = tx.amount_minor / allAverage;
      if (deviation >= 4 && tx.amount_minor >= 250000) kind = "unusual";
    }
    if (!kind) continue;

    anomalyModels.push({
      title: kind === "category"
        ? (isId ? `Kebocoran di ${category?.name ?? "kategori"}` : `Leak in ${category?.name ?? "category"}`)
        : (isId ? "Nominal tidak biasa" : "Unusual amount"),
      detail: isId
        ? `${tx.merchant?.trim() || tx.note?.trim() || "Transaksi"} ${formatMoney(tx.amount_minor, currency, localeCode)} – ${deviation.toFixed(1)}× rata-rata historis.`
        : `${tx.merchant?.trim() || tx.note?.trim() || "Transaction"} ${formatMoney(tx.amount_minor, currency, localeCode)} – ${deviation.toFixed(1)}× the historical average.`,
      transaction_id: tx.id,
      amount_minor: tx.amount_minor,
      currency: tx.currency,
      severity: deviation >= 4 ? "critical" : "warning",
    });
  }
  anomalyModels.sort((a, b) => (b.amount_minor ?? 0) - (a.amount_minor ?? 0));

  const overBudget = budgetProgress.filter((item) => item.ratio >= 1);
  const recommendations: string[] = [];
  if (top?.category) {
    recommendations.push(
      isId
        ? `Tetapkan batas mingguan untuk ${top.category.name} dan tinjau setiap Jumat.`
        : `Set a weekly cap for ${top.category.name} and review it every Friday.`,
    );
  }
  if (overBudget[0]) {
    const category = categories.get(overBudget[0].budget.category_id);
    if (category) {
      recommendations.push(
        isId
          ? `Pindahkan sisa anggaran dari kategori aman untuk menutup Batas TKP ${category.name}.`
          : `Move leftover budget from safe categories to cover the ${category.name} crime scene.`,
      );
    }
  }
  if (anomalyModels[0]) {
    recommendations.push(
      isId
        ? "Buka barang bukti terbesar dan konfirmasi apakah pengeluaran itu berulang."
        : "Open the largest piece of evidence and confirm whether the expense recurs.",
    );
  }
  recommendations.push(
    isId
      ? "Aktifkan kunci biometrik dan tinjau berkas ini saat offline agar data tetap aman."
      : "Keep biometric lock on and review this file offline so the data stays protected.",
  );

  const scope = walletName
    ? (isId ? ` di ${walletName}` : ` in ${walletName}`)
    : "";
  const headline = overBudget.length
    ? (isId
      ? `${overBudget.length} Batas TKP jebol${scope}`
      : `${overBudget.length} crime scene${overBudget.length === 1 ? "" : "s"} exceeded the line${scope}`)
    : (isId
      ? `Arus kas terkendali, satu titik perlu diawasi${scope}`
      : `Cash flow is under control, one lead needs watching${scope}`);

  const summary = isId
    ? `Dari ${transactions.length} transaksi pada ${periodLabel(from, to, localeCode)}, pemasukan ${formatMoney(income, currency, localeCode)} dan pengeluaran ${formatMoney(expense, currency, localeCode)}. Selisih bersih ${formatMoney(net, currency, localeCode)}. Laporan ini disusun dari berkas cloud yang bisa diakses akunmu.`
    : `Across ${transactions.length} transactions in ${periodLabel(from, to, localeCode)}, income was ${formatMoney(income, currency, localeCode)} and spending was ${formatMoney(expense, currency, localeCode)}. Net difference ${formatMoney(net, currency, localeCode)}. This report was assembled from cloud records available to your account.`;

  return {
    headline,
    summary,
    findings: findings.slice(0, 5),
    anomalies: anomalyModels.slice(0, 3),
    recommendations: recommendations.slice(0, 4),
  };
}

async function askAi(input: {
  localeCode: string;
  from: Date;
  to: Date;
  walletName: string | null;
  transactions: TransactionRow[];
  categories: Map<string, CategoryRow>;
  budgets: BudgetRow[];
  heuristic: ReportPayload;
}): Promise<ReportPayload | null> {
  const apiKey = Deno.env.get("AI_API_KEY") ??
    Deno.env.get("OPENROUTER_API_KEY");
  if (!apiKey) return null;

  const baseUrl = (Deno.env.get("AI_BASE_URL") ??
    "https://openrouter.ai/api/v1").replace(/\/+$/, "");
  const model = Deno.env.get("AI_MODEL") ??
    "google/gemini-2.0-flash-exp:free";
  const isId = input.localeCode !== "en";
  const currency = input.transactions[0]?.currency ?? "IDR";
  const totalExpense = input.transactions
    .filter((tx) => tx.type === "expense")
    .reduce((sum, tx) => sum + tx.amount_minor, 0);

  const categoryTotals = new Map<string, number>();
  for (const tx of input.transactions) {
    if (tx.type !== "expense" || !tx.category_id) continue;
    categoryTotals.set(
      tx.category_id,
      (categoryTotals.get(tx.category_id) ?? 0) + tx.amount_minor,
    );
  }
  const compact = {
    locale: isId ? "id" : "en",
    period: {
      from: input.from.toISOString(),
      to: input.to.toISOString(),
      label: periodLabel(input.from, input.to, input.localeCode),
    },
    wallet: input.walletName,
    totals: {
      transactions: input.transactions.length,
      income_minor: input.transactions
        .filter((tx) => tx.type === "income")
        .reduce((sum, tx) => sum + tx.amount_minor, 0),
      expense_minor: totalExpense,
      net_minor: input.transactions.reduce(
        (sum, tx) =>
          sum + (tx.type === "income" ? tx.amount_minor : tx.type === "expense" ? -tx.amount_minor : 0),
        0,
      ),
      currency,
    },
    categories: [...categoryTotals.entries()]
      .map(([id, amount]) => ({
        name: input.categories.get(id)?.name ?? "Unknown",
        amount_minor: amount,
        ratio: roundRatio(totalExpense ? amount / totalExpense : 0),
      }))
      .sort((a, b) => b.amount_minor - a.amount_minor)
      .slice(0, 8),
    budgets: input.budgets
      .map((budget) => ({
        category: input.categories.get(budget.category_id)?.name ?? "Unknown",
        limit_minor: budget.amount_minor,
        alert_threshold: budget.alert_threshold,
      }))
      .slice(0, 12),
    recent_expenses: input.transactions
      .filter((tx) => tx.type === "expense")
      .sort((a, b) => b.amount_minor - a.amount_minor)
      .slice(0, 20)
      .map((tx) => ({
        id: tx.id,
        merchant: tx.merchant?.trim() || tx.note?.trim() || "",
        category: tx.category_id
          ? input.categories.get(tx.category_id)?.name ?? "Unknown"
          : null,
        amount_minor: tx.amount_minor,
        currency: tx.currency,
        occurred_at: tx.occurred_at,
      })),
    deterministic_signals: {
      findings: input.heuristic.findings,
      anomalies: input.heuristic.anomalies,
    },
  };

  const system = isId
    ? "Kamu adalah analis keuangan forensik untuk aplikasi Dompetektif. Gunakan bahasa Indonesia yang tajam, hangat, dan tidak menghakimi. Jangan mengarang angka atau transaksi. Jawab hanya dengan JSON valid tanpa markdown."
    : "You are a forensic finance analyst for Dompetektif. Use sharp, warm, non-judgmental English. Never invent numbers or transactions. Reply with valid JSON only, no markdown.";
  const user = `Analisis data berikut dan hasilkan laporan investigasi.\n\n${JSON.stringify(compact)}\n\nBalas dengan skema JSON ini:\n{"headline":"string singkat","summary":"2-3 kalimat","findings":[{"title":"string","detail":"string","severity":"info|warning|critical"}],"anomalies":[{"title":"string","detail":"string","transaction_id":"uuid atau null","amount_minor":number|null,"currency":"IDR","severity":"info|warning|critical"}],"recommendations":["string"]}\nMaksimal 5 findings, 3 anomalies, 4 recommendations. Sebut nominal dalam mata uang data.`;

  try {
    const response = await fetch(`${baseUrl}/chat/completions`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${apiKey}`,
        "Content-Type": "application/json",
        "HTTP-Referer": "https://dompetektif.app",
        "X-Title": "Dompetektif",
      },
      body: JSON.stringify({
        model,
        temperature: 0.25,
        max_tokens: 1200,
        messages: [
          { role: "system", content: system },
          { role: "user", content: user },
        ],
      }),
      signal: AbortSignal.timeout(25_000),
    });
    if (!response.ok) {
      console.warn("AI provider rejected request", response.status, await response.text());
      return null;
    }
    const data = await response.json();
    const content = data?.choices?.[0]?.message?.content;
    if (typeof content !== "string") return null;
    const fenced = content.match(/```(?:json)?\s*([\s\S]*?)```/i);
    const raw = (fenced ? fenced[1] : content).trim();
    const parsed = JSON.parse(raw);

    const findings: Finding[] = Array.isArray(parsed.findings)
      ? parsed.findings
        .map((item: any) => ({
          title: clampText(item?.title, 120),
          detail: clampText(item?.detail, 500),
          severity: toSeverity(item?.severity),
        }))
        .filter((item: Finding) => item.title && item.detail)
        .slice(0, 5)
      : [];
    const txById = new Map(input.transactions.map((tx) => [tx.id, tx]));
    const anomalies: Anomaly[] = Array.isArray(parsed.anomalies)
      ? parsed.anomalies
        .map((item: any) => {
          // Never trust model-supplied amounts: resolve them from the row.
          const linked = typeof item?.transaction_id === "string"
            ? txById.get(item.transaction_id)
            : undefined;
          return {
            title: clampText(item?.title, 120),
            detail: clampText(item?.detail, 500),
            transaction_id: linked?.id ?? null,
            amount_minor: linked?.amount_minor ?? null,
            currency: linked?.currency ?? null,
            severity: toSeverity(item?.severity, "warning"),
          };
        })
        .filter((item: Anomaly) => item.title && item.detail)
        .slice(0, 3)
      : [];
    const recommendations: string[] = Array.isArray(parsed.recommendations)
      ? parsed.recommendations
        .map((item: unknown) => clampText(item, 300))
        .filter((item: string) => item.length > 0)
        .slice(0, 4)
      : [];
    const headline = clampText(parsed.headline, 160);
    const summary = clampText(parsed.summary, 900);
    if (!headline || !summary) return null;

    return {
      headline,
      summary,
      findings: findings.length ? findings : input.heuristic.findings,
      anomalies: anomalies.length ? anomalies : input.heuristic.anomalies,
      recommendations:
        recommendations.length ? recommendations : input.heuristic.recommendations,
    };
  } catch (cause) {
    console.warn("AI report fallback", cause);
    return null;
  }
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") return error("Metode tidak didukung.", 405);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
    if (!supabaseUrl || !anonKey) {
      return error("Supabase environment tidak tersedia.", 500);
    }

    const authHeader = request.headers.get("Authorization");
    if (!authHeader?.startsWith("Bearer ")) {
      return error("Sesi tidak ditemukan.", 401);
    }

    const supabase = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const token = authHeader.slice("Bearer ".length);
    const {
      data: { user },
      error: authError,
    } = await supabase.auth.getUser(token);

    if (authError || !user) return error("Sesi tidak valid.", 401);

    let body: any;
    try {
      body = await request.json();
    } catch {
      return error("Body JSON tidak valid.");
    }

    const walletId = typeof body?.wallet_id === "string" && body.wallet_id.length
      ? body.wallet_id
      : null;
    const from = new Date(body?.from);
    const to = new Date(body?.to);
    const localeCode = body?.locale === "en" ? "en" : "id";
    if (Number.isNaN(from.getTime()) || Number.isNaN(to.getTime())) {
      return error("Rentang tanggal tidak valid.");
    }
    if (from > to) return error("Tanggal mulai harus sebelum tanggal akhir.");
    if (to.getTime() - from.getTime() > 1000 * 60 * 60 * 24 * 400) {
      return error("Rentang laporan maksimal 400 hari.");
    }

    let walletName: string | null = null;
    if (walletId) {
      const { data: wallet, error: walletError } = await supabase
        .from("wallets")
        .select("id,name,currency,deleted_at")
        .eq("id", walletId)
        .is("deleted_at", null)
        .maybeSingle();
      if (walletError || !wallet) {
        return error("TKP tidak ditemukan atau bukan milikmu.", 404);
      }
      walletName = (wallet as WalletRow).name;
    }

    const historyStart = new Date(from.getTime() - 1000 * 60 * 60 * 24 * 90);
    let transactionsQuery = supabase
      .from("transactions")
      .select(
        "id,wallet_id,type,amount_minor,currency,category_id,occurred_at,merchant,note",
      )
      .is("deleted_at", null)
      .gte("occurred_at", historyStart.toISOString())
      .lte("occurred_at", to.toISOString())
      .order("occurred_at", { ascending: false })
      .limit(3000);
    if (walletId) transactionsQuery = transactionsQuery.eq("wallet_id", walletId);

    const { data: transactionRows, error: transactionsError } =
      await transactionsQuery;
    if (transactionsError) {
      console.error(transactionsError);
      return error("Gagal membaca transaksi.", 500);
    }

    const { data: categoryRows, error: categoriesError } = await supabase
      .from("categories")
      .select("id,name,kind,color_hex");
    if (categoriesError) {
      console.error(categoriesError);
      return error("Gagal membaca kategori.", 500);
    }

    let budgetsQuery = supabase
      .from("budgets")
      .select(
        "id,wallet_id,category_id,amount_minor,currency,month,alert_threshold",
      )
      .is("deleted_at", null)
      .gte("month", monthStart(from))
      .lte("month", monthStart(to));
    if (walletId) {
      budgetsQuery = budgetsQuery.or(`wallet_id.is.null,wallet_id.eq.${walletId}`);
    }
    const { data: budgetRows, error: budgetsError } = await budgetsQuery;
    if (budgetsError) console.warn("Budget query skipped", budgetsError);
    const budgets = (budgetRows ?? []) as BudgetRow[];

    const categories = new Map<string, CategoryRow>(
      ((categoryRows ?? []) as CategoryRow[]).map((row) => [row.id, row]),
    );
    const all = (transactionRows ?? []) as TransactionRow[];
    const current = all.filter((tx) => {
      const occurred = new Date(tx.occurred_at).getTime();
      return occurred >= from.getTime() && occurred <= to.getTime();
    });
    const history = all.filter(
      (tx) => new Date(tx.occurred_at).getTime() < from.getTime(),
    );

    const heuristic = computeHeuristic({
      localeCode,
      from,
      to,
      walletName,
      transactions: current,
      history,
      categories,
      budgets,
    });
    const ai = await askAi({
      localeCode,
      from,
      to,
      walletName,
      transactions: current,
      categories,
      budgets,
      heuristic,
    });
    const report = ai ?? heuristic;
    const now = new Date().toISOString();

    return json({
      id: crypto.randomUUID(),
      owner_id: user.id,
      wallet_id: walletId,
      period_start: from.toISOString(),
      period_end: to.toISOString(),
      headline: report.headline,
      summary: report.summary,
      findings: report.findings,
      anomalies: report.anomalies,
      recommendations: report.recommendations,
      source: ai ? "ai" : "heuristic",
      generated_at: now,
      updated_at: now,
    });
  } catch (cause) {
    console.error("investigation-report failed", cause);
    return error("Laporan gagal disusun. Coba lagi.", 500);
  }
});
