-- CL03; VT 2026-05-05; TT 2026-05-11 12:00 UTC
SELECT * FROM v_q6_bitemporal_point WHERE fact_kind='CONTRACT' ORDER BY subject_code,valid_from,version_id;
