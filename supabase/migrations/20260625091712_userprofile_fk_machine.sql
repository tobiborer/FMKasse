-- Ordnet einen Benutzer optional einer Kasse (machine) zu.
-- Diese Kasse wird beim Login automatisch als aktives Gerät übernommen –
-- relevant für Benutzer ohne Admin-Rechte, die in den Einstellungen kein
-- Gerät selbst wählen können.

alter table public.userprofile
    add column if not exists fk_machine bigint
        references public.machine (id) on delete set null;

comment on column public.userprofile.fk_machine is
    'Optional zugeordnete Kasse; wird beim Login als aktives Gerät übernommen.';
