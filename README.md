Overview
Crypto Will is a trustless inheritance smart contract for Bitcoin/STX assets on the Stacks blockchain. It enables users to create a vault, designate heirs with percentage shares, and automatically allow heirs to claim funds if the owner becomes inactive for a set period.

Features
Vault Creation: Lock funds and specify multiple heirs with percentage allocations.
Inactivity Detection: Heirs can claim funds if the owner does not interact with the contract for a configurable period.
Ping Mechanism: Owners can reset their inactivity timer by pinging the contract.
Secure Claims: Only designated heirs can claim, and only after the inactivity period and claimable-after block.
Transparent Storage: Vault and heir data are stored on-chain for auditability.
Usage
1. Create a Vault
Owners call create-vault with:

amount: Amount to lock.
claim-after: Block height after which heirs can claim.
heirs-list: List of heirs and their percentage shares (must sum to 100).
2. Ping the Contract
Owners call ping to reset their inactivity timer and keep their vault secure.

3. Claim Funds
Heirs call claim with the owner's principal. If the inactivity period and claim-after block have passed, heirs can claim their share.

4. Read Vault and Heir Info
get-vault: View vault details for any owner.
get-heir-percentage: View the percentage share for a specific heir.
Error Codes
ERR_UNAUTHORIZED: Unauthorized action.
ERR_VAULT_EXISTS: Vault already exists.
ERR_VAULT_NOT_FOUND: Vault not found.
ERR_NOT_HEIR: Caller is not an heir.
ERR_TOO_SOON: Claim attempted before allowed.
ERR_INVALID_PERCENT: Invalid percentage allocation.
ERR_ZERO_AMOUNT: Amount must be greater than zero.
