-- Project Assistant memory foundation
-- Architecture contract: PROJECT-ASSISTANT-MEMORY-ARCHITECTURE.md
-- Phase 1: persistence, ownership, review gates, and auditability

begin;

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = public
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------------
-- Projects and access
-- ---------------------------------------------------------------------------

create table public.projects (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid,
  name text not null check (char_length(btrim(name)) between 1 and 200),
  description text,
  owner_user_id uuid not null references auth.users(id) on delete restrict,
  status text not null default 'active'
    check (status in ('draft', 'active', 'paused', 'archived')),
  visibility_scope text not null default 'private'
    check (visibility_scope in ('private', 'project', 'organization')),
  sensitivity_level text not null default 'standard'
    check (sensitivity_level in ('standard', 'confidential', 'restricted', 'highly_restricted')),
  jurisdiction text,
  purpose text,
  baseline_version integer not null default 1 check (baseline_version >= 1),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id) on delete restrict,
  version integer not null default 1 check (version >= 1)
);

create table public.project_members (
  project_id uuid not null references public.projects(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  role text not null check (role in ('owner', 'admin', 'editor', 'reviewer', 'viewer')),
  status text not null default 'active' check (status in ('invited', 'active', 'suspended', 'removed')),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  primary key (project_id, user_id)
);

create index projects_owner_user_id_idx on public.projects(owner_user_id);
create index project_members_user_id_idx on public.project_members(user_id);

create or replace function public.is_project_member(target_project_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.project_members pm
    where pm.project_id = target_project_id
      and pm.user_id = auth.uid()
      and pm.status = 'active'
  );
$$;

create or replace function public.has_project_role(target_project_id uuid, allowed_roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.project_members pm
    where pm.project_id = target_project_id
      and pm.user_id = auth.uid()
      and pm.status = 'active'
      and pm.role = any(allowed_roles)
  );
$$;

revoke all on function public.is_project_member(uuid) from public;
revoke all on function public.has_project_role(uuid, text[]) from public;
grant execute on function public.is_project_member(uuid) to authenticated;
grant execute on function public.has_project_role(uuid, text[]) to authenticated;

create or replace function public.add_project_owner_membership()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.project_members (project_id, user_id, role, status, created_by)
  values (new.id, new.owner_user_id, 'owner', 'active', new.created_by)
  on conflict (project_id, user_id) do update
    set role = 'owner', status = 'active';
  return new;
end;
$$;

create trigger projects_add_owner_membership
after insert on public.projects
for each row execute function public.add_project_owner_membership();

create trigger projects_set_updated_at
before update on public.projects
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Core memory tables
-- ---------------------------------------------------------------------------

create table public.checkpoints (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  label text not null check (char_length(btrim(label)) between 1 and 200),
  summary text,
  state_snapshot jsonb not null default '{}'::jsonb,
  baseline_version integer not null check (baseline_version >= 1),
  is_locked boolean not null default false,
  status text not null default 'active' check (status in ('active', 'superseded', 'archived')),
  source_type text not null default 'human' check (source_type in ('human', 'system', 'ai', 'import')),
  confidence numeric(4,3) check (confidence is null or confidence between 0 and 1),
  visibility_scope text not null default 'project' check (visibility_scope in ('private', 'project', 'organization')),
  sensitivity_level text not null default 'standard' check (sensitivity_level in ('standard', 'confidential', 'restricted', 'highly_restricted')),
  is_ai_generated boolean not null default false,
  requires_human_review boolean not null default false,
  review_status text not null default 'not_required' check (review_status in ('not_required', 'pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  version integer not null default 1 check (version >= 1)
);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  event_type text not null,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  description text,
  occurred_at timestamptz not null default now(),
  evidence_class text not null default 'user_reported'
    check (evidence_class in ('verified_fact', 'user_reported', 'interpretation', 'suggestion', 'prediction', 'simulation', 'professional_decision')),
  source_type text not null default 'human' check (source_type in ('human', 'system', 'ai', 'import')),
  source_reference text,
  context_snapshot jsonb not null default '{}'::jsonb,
  confidence numeric(4,3) check (confidence is null or confidence between 0 and 1),
  sensitivity_level text not null default 'standard' check (sensitivity_level in ('standard', 'confidential', 'restricted', 'highly_restricted')),
  is_ai_generated boolean not null default false,
  requires_human_review boolean not null default false,
  review_status text not null default 'not_required' check (review_status in ('not_required', 'pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  version integer not null default 1 check (version >= 1)
);

create table public.decisions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 200),
  question text,
  decision_text text not null,
  rationale text,
  evidence jsonb not null default '[]'::jsonb,
  decision_status text not null default 'proposed' check (decision_status in ('proposed', 'approved', 'rejected', 'superseded')),
  impact_level text not null default 'normal' check (impact_level in ('normal', 'high', 'regulated')),
  final_decision_by uuid references auth.users(id) on delete restrict,
  final_decision_at timestamptz,
  is_ai_generated boolean not null default false,
  requires_human_review boolean not null default true,
  review_status text not null default 'pending' check (review_status in ('pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id) on delete restrict,
  version integer not null default 1 check (version >= 1),
  check (
    decision_status <> 'approved'
    or (final_decision_by is not null and final_decision_at is not null and review_status = 'approved')
  )
);

create table public.artifacts (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  name text not null check (char_length(btrim(name)) between 1 and 255),
  artifact_type text not null,
  storage_path text,
  external_url text,
  mime_type text,
  checksum_sha256 text,
  status text not null default 'draft' check (status in ('draft', 'review', 'approved', 'archived')),
  sensitivity_level text not null default 'standard' check (sensitivity_level in ('standard', 'confidential', 'restricted', 'highly_restricted')),
  is_ai_generated boolean not null default false,
  requires_human_review boolean not null default false,
  review_status text not null default 'not_required' check (review_status in ('not_required', 'pending', 'approved', 'rejected')),
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  updated_at timestamptz not null default now(),
  updated_by uuid not null references auth.users(id) on delete restrict,
  version integer not null default 1 check (version >= 1),
  check (storage_path is not null or external_url is not null)
);

-- ---------------------------------------------------------------------------
-- Consent and human-review gates
-- ---------------------------------------------------------------------------

create table public.consent_records (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  subject_user_id uuid references auth.users(id) on delete set null,
  consent_type text not null,
  purpose text not null,
  data_categories text[] not null default '{}',
  policy_version text not null,
  consent_status text not null check (consent_status in ('granted', 'refused', 'withdrawn', 'expired')),
  granted_at timestamptz,
  withdrawn_at timestamptz,
  expires_at timestamptz,
  evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  check (consent_status <> 'granted' or granted_at is not null),
  check (consent_status <> 'withdrawn' or withdrawn_at is not null)
);

create table public.safety_interruptions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  warning_type text not null,
  warning_version text not null,
  trigger_category text not null,
  trigger_reference_type text,
  trigger_reference_id uuid,
  displayed_at timestamptz not null default now(),
  displayed_to uuid not null references auth.users(id) on delete restrict,
  user_response text not null check (user_response in ('continue_authorized', 'continue_deidentified', 'contact_professional', 'cancel')),
  consent_record_id uuid references public.consent_records(id) on delete restrict,
  professional_review_required boolean not null default true,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict
);

create table public.professional_reviews (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  safety_interruption_id uuid references public.safety_interruptions(id) on delete restrict,
  reviewer_user_id uuid references auth.users(id) on delete restrict,
  reviewer_name text not null,
  professional_role text not null,
  license_type text,
  license_jurisdiction text,
  license_reference text,
  license_verified boolean not null default false,
  evidence_reviewed jsonb not null default '[]'::jsonb,
  ai_output_reviewed text,
  review_status text not null check (review_status in ('pending', 'approved', 'rejected', 'needs_more_information')),
  reviewed_at timestamptz,
  reviewer_confirmation boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  check (
    review_status not in ('approved', 'rejected')
    or (reviewed_at is not null and reviewer_confirmation = true)
  )
);

create table public.human_decisions (
  id uuid primary key default gen_random_uuid(),
  project_id uuid not null references public.projects(id) on delete cascade,
  decision_id uuid references public.decisions(id) on delete restrict,
  professional_review_id uuid references public.professional_reviews(id) on delete restrict,
  decision_category text not null,
  final_decision text not null,
  differences_from_ai text,
  decided_by uuid not null references auth.users(id) on delete restrict,
  decided_at timestamptz not null default now(),
  authority_basis text not null,
  confirmation boolean not null default false,
  created_at timestamptz not null default now(),
  created_by uuid not null references auth.users(id) on delete restrict,
  check (confirmation = true)
);

alter table public.safety_interruptions
  add column professional_review_id uuid references public.professional_reviews(id) on delete restrict,
  add column final_human_decision_id uuid references public.human_decisions(id) on delete restrict;

-- ---------------------------------------------------------------------------
-- Append-only audit log
-- ---------------------------------------------------------------------------

create table public.audit_events (
  id bigint generated always as identity primary key,
  project_id uuid references public.projects(id) on delete restrict,
  actor_user_id uuid references auth.users(id) on delete set null,
  action text not null,
  target_table text not null,
  target_id text,
  before_state jsonb,
  after_state jsonb,
  request_id text,
  ip_hash text,
  user_agent_hash text,
  occurred_at timestamptz not null default now()
);

create index checkpoints_project_created_idx on public.checkpoints(project_id, created_at desc);
create index events_project_occurred_idx on public.events(project_id, occurred_at desc);
create index decisions_project_created_idx on public.decisions(project_id, created_at desc);
create index artifacts_project_created_idx on public.artifacts(project_id, created_at desc);
create index consent_records_project_created_idx on public.consent_records(project_id, created_at desc);
create index safety_interruptions_project_created_idx on public.safety_interruptions(project_id, created_at desc);
create index professional_reviews_project_created_idx on public.professional_reviews(project_id, created_at desc);
create index human_decisions_project_decided_idx on public.human_decisions(project_id, decided_at desc);
create index audit_events_project_occurred_idx on public.audit_events(project_id, occurred_at desc);

create trigger decisions_set_updated_at
before update on public.decisions
for each row execute function public.set_updated_at();

create trigger artifacts_set_updated_at
before update on public.artifacts
for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------------
-- Row-level security
-- ---------------------------------------------------------------------------

alter table public.projects enable row level security;
alter table public.project_members enable row level security;
alter table public.checkpoints enable row level security;
alter table public.events enable row level security;
alter table public.decisions enable row level security;
alter table public.artifacts enable row level security;
alter table public.consent_records enable row level security;
alter table public.safety_interruptions enable row level security;
alter table public.professional_reviews enable row level security;
alter table public.human_decisions enable row level security;
alter table public.audit_events enable row level security;

create policy projects_insert_own
on public.projects for insert to authenticated
with check (owner_user_id = auth.uid() and created_by = auth.uid() and updated_by = auth.uid());

create policy projects_select_member
on public.projects for select to authenticated
using (public.is_project_member(id));

create policy projects_update_admin
on public.projects for update to authenticated
using (public.has_project_role(id, array['owner', 'admin']))
with check (public.has_project_role(id, array['owner', 'admin']) and updated_by = auth.uid());

create policy project_members_select_member
on public.project_members for select to authenticated
using (public.is_project_member(project_id));

create policy project_members_manage_admin
on public.project_members for all to authenticated
using (public.has_project_role(project_id, array['owner', 'admin']))
with check (public.has_project_role(project_id, array['owner', 'admin']));

create policy checkpoints_select_member
on public.checkpoints for select to authenticated
using (public.is_project_member(project_id));

create policy checkpoints_insert_editor
on public.checkpoints for insert to authenticated
with check (public.has_project_role(project_id, array['owner', 'admin', 'editor']) and created_by = auth.uid());

create policy checkpoints_update_editor
on public.checkpoints for update to authenticated
using (public.has_project_role(project_id, array['owner', 'admin', 'editor']) and is_locked = false)
with check (public.has_project_role(project_id, array['owner', 'admin', 'editor']));

create policy events_select_member
on public.events for select to authenticated
using (public.is_project_member(project_id));

create policy events_insert_editor
on public.events for insert to authenticated
with check (public.has_project_role(project_id, array['owner', 'admin', 'editor']) and created_by = auth.uid());

create policy decisions_select_member
on public.decisions for select to authenticated
using (public.is_project_member(project_id));

create policy decisions_insert_editor
on public.decisions for insert to authenticated
with check (public.has_project_role(project_id, array['owner', 'admin', 'editor']) and created_by = auth.uid() and updated_by = auth.uid());

create policy decisions_update_reviewer
on public.decisions for update to authenticated
using (public.has_project_role(project_id, array['owner', 'admin', 'editor', 'reviewer']))
with check (public.has_project_role(project_id, array['owner', 'admin', 'editor', 'reviewer']) and updated_by = auth.uid());

create policy artifacts_select_member
on public.artifacts for select to authenticated
using (public.is_project_member(project_id));

create policy artifacts_insert_editor
on public.artifacts for insert to authenticated
with check (public.has_project_role(project_id, array['owner', 'admin', 'editor']) and created_by = auth.uid() and updated_by = auth.uid());

create policy artifacts_update_editor
on public.artifacts for update to authenticated
using (public.has_project_role(project_id, array['owner', 'admin', 'editor']))
with check (public.has_project_role(project_id, array['owner', 'admin', 'editor']) and updated_by = auth.uid());

create policy consent_records_select_reviewer
on public.consent_records for select to authenticated
using (public.has_project_role(project_id, array['owner', 'admin', 'reviewer']) or subject_user_id = auth.uid());

create policy consent_records_insert_self_or_admin
on public.consent_records for insert to authenticated
with check (
  created_by = auth.uid()
  and (subject_user_id = auth.uid() or public.has_project_role(project_id, array['owner', 'admin']))
);

create policy safety_interruptions_select_reviewer
on public.safety_interruptions for select to authenticated
using (public.has_project_role(project_id, array['owner', 'admin', 'reviewer']) or displayed_to = auth.uid());

create policy safety_interruptions_insert_member
on public.safety_interruptions for insert to authenticated
with check (public.is_project_member(project_id) and displayed_to = auth.uid() and created_by = auth.uid());

create policy professional_reviews_select_reviewer
on public.professional_reviews for select to authenticated
using (public.has_project_role(project_id, array['owner', 'admin', 'reviewer']) or reviewer_user_id = auth.uid());

create policy professional_reviews_insert_reviewer
on public.professional_reviews for insert to authenticated
with check (
  created_by = auth.uid()
  and (reviewer_user_id = auth.uid() or public.has_project_role(project_id, array['owner', 'admin']))
);

create policy professional_reviews_update_reviewer
on public.professional_reviews for update to authenticated
using (reviewer_user_id = auth.uid() or public.has_project_role(project_id, array['owner', 'admin']))
with check (reviewer_user_id = auth.uid() or public.has_project_role(project_id, array['owner', 'admin']));

create policy human_decisions_select_reviewer
on public.human_decisions for select to authenticated
using (public.has_project_role(project_id, array['owner', 'admin', 'reviewer']) or decided_by = auth.uid());

create policy human_decisions_insert_authorized
on public.human_decisions for insert to authenticated
with check (
  created_by = auth.uid()
  and decided_by = auth.uid()
  and public.has_project_role(project_id, array['owner', 'admin', 'reviewer'])
);

create policy audit_events_select_admin
on public.audit_events for select to authenticated
using (public.has_project_role(project_id, array['owner', 'admin']));

-- Client roles intentionally receive no UPDATE or DELETE policy for audit_events.
-- Service-side audit writers must use a protected server role and validated code.

-- ---------------------------------------------------------------------------
-- Grants
-- ---------------------------------------------------------------------------

grant select, insert, update on public.projects to authenticated;
grant select, insert, update, delete on public.project_members to authenticated;
grant select, insert, update on public.checkpoints to authenticated;
grant select, insert on public.events to authenticated;
grant select, insert, update on public.decisions to authenticated;
grant select, insert, update on public.artifacts to authenticated;
grant select, insert on public.consent_records to authenticated;
grant select, insert on public.safety_interruptions to authenticated;
grant select, insert, update on public.professional_reviews to authenticated;
grant select, insert on public.human_decisions to authenticated;
grant select on public.audit_events to authenticated;

commit;  
