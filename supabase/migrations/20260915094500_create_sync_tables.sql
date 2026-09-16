-- Sync tables for the Tether Health session service.
--
-- No BEGIN/COMMIT: the migration runner wraps each file in its own
-- transaction, and a nested one here would commit half of this file early.
--
-- The unit of everything below is (account_id, area_id) — one person's one
-- programme. See thsync/repository.py for why that, and not the session
-- document, is what this service stores.

CREATE TABLE IF NOT EXISTS sync_account (
    account_id  varchar(128) PRIMARY KEY,
    -- Per-account change counter. Every write to any of this account's areas
    -- claims the next value, which is what lets one integer cursor describe
    -- "everything I have seen" across independently versioned programmes.
    change_seq  bigint       NOT NULL DEFAULT 0,
    created_at  timestamptz  NOT NULL,
    updated_at  timestamptz  NOT NULL
);

CREATE TABLE IF NOT EXISTS sync_area (
    account_id                 varchar(128) NOT NULL
        REFERENCES sync_account (account_id) ON DELETE CASCADE,
    area_id                    varchar(64)  NOT NULL,
    -- Monotonic per area. A push carrying a different value for this area is
    -- a conflict and is returned to the client, never merged here.
    revision                   bigint      NOT NULL,
    change_seq                 bigint      NOT NULL,
    -- A revoked area keeps this row and nothing else: the id, the revision and
    -- the flag, so the person's other device learns to delete its copy. Every
    -- enrolment column below is NULL once this is true.
    revoked                    boolean     NOT NULL DEFAULT false,
    enrolment_status           varchar(16),
    enrolment_hidden           boolean,
    joined_on                  timestamptz,
    share_totals_and_adherence boolean,
    share_notes                boolean,
    share_recipient            varchar(256),
    updated_at                 timestamptz NOT NULL,
    PRIMARY KEY (account_id, area_id)
);

-- Leads with account_id because every query in the service does, and because
-- an index that could serve a query scanning across accounts is an index that
-- makes such a query cheap enough to survive review.
CREATE INDEX IF NOT EXISTS sync_area_change_seq_idx
    ON sync_area (account_id, change_seq);

CREATE TABLE IF NOT EXISTS sync_answer (
    account_id varchar(128) NOT NULL,
    area_id    varchar(64)  NOT NULL,
    -- Bare screen id. The client sends `areaId/screenId`; the prefix is checked
    -- against area_id and then dropped, so a stored answer cannot name one
    -- programme in its key and sit in another's row.
    screen_id  varchar(64)  NOT NULL,
    payload    jsonb        NOT NULL,
    updated_at timestamptz NOT NULL,
    PRIMARY KEY (account_id, area_id, screen_id),
    FOREIGN KEY (account_id, area_id)
        REFERENCES sync_area (account_id, area_id) ON DELETE CASCADE
);

CREATE TABLE IF NOT EXISTS sync_lapse (
    account_id varchar(128) NOT NULL,
    area_id    varchar(64)  NOT NULL,
    -- Position in the client's list rather than a surrogate key: the client
    -- replaces the whole list on every push, so the index is the identity and
    -- the order survives without a separate sort column.
    ordinal    integer     NOT NULL,
    at         timestamptz NOT NULL,
    severity   varchar(64)  NOT NULL,
    context    jsonb       NOT NULL,
    PRIMARY KEY (account_id, area_id, ordinal),
    FOREIGN KEY (account_id, area_id)
        REFERENCES sync_area (account_id, area_id) ON DELETE CASCADE
);
