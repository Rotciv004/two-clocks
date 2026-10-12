CREATE INDEX ix_p3_contract_fk_support ON contract_version(contract_id);
ALTER TABLE contract_version DROP INDEX ix_contract_version_asof;
CREATE INDEX ix_contract_version_asof ON contract_version(contract_id,tx_to,valid_from);
DROP INDEX ix_p3_contract_fk_support ON contract_version;
