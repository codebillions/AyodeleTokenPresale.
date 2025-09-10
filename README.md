# AyodeleTokenPresale

**Project:** Ayodele Token & Presale  
**Client:** Ayodele Johnson (Lagos, Nigeria) — shared with permission for portfolio purposes.

## Overview
End-to-end token + presale system with:
- ERC20 token (capped, burnable, pausable)
- Presale contract with whitelist, soft/hard cap, refunds
- React frontend to connect wallet and buy tokens
- Hardhat scripts & tests

## Quick local dev
1. Install:
   ```
   npm install
   cd frontend && npm install
   ```
2. Compile & test:
   ```
   npx hardhat compile
   npx hardhat test
   ```
3. Run local node + deploy:
   ```
   npx hardhat node
   # in new terminal
   npx hardhat run --network localhost scripts/deploy.js
   ```
4. Update `frontend/src/App.js` with deployed presale address and run:
   ```
   cd frontend
   npm start
   ```
