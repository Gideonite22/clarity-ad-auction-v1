import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
    name: "Test auction creation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        
        let block = chain.mineBlock([
            // Create auction as owner
            Tx.contractCall('ad-auction', 'create-auction', [
                types.ascii("Banner Ad Space #1"),
                types.uint(100)
            ], deployer.address),
            
            // Try to create auction as non-owner
            Tx.contractCall('ad-auction', 'create-auction', [
                types.ascii("Banner Ad Space #2"),
                types.uint(100)
            ], wallet1.address)
        ]);
        
        block.receipts[0].result.expectOk().expectUint(0);
        block.receipts[1].result.expectErr().expectUint(100); // err-owner-only
    }
});

Clarinet.test({
    name: "Test bidding flow",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const wallet1 = accounts.get('wallet_1')!;
        const wallet2 = accounts.get('wallet_2')!;
        
        // Create auction
        let block1 = chain.mineBlock([
            Tx.contractCall('ad-auction', 'create-auction', [
                types.ascii("Banner Ad Space #1"),
                types.uint(100)
            ], deployer.address)
        ]);
        
        // Place bids
        let block2 = chain.mineBlock([
            Tx.contractCall('ad-auction', 'place-bid', [
                types.uint(0),
                types.uint(2000)
            ], wallet1.address),
            
            Tx.contractCall('ad-auction', 'place-bid', [
                types.uint(0),
                types.uint(1000)
            ], wallet2.address)
        ]);
        
        block2.receipts[0].result.expectOk().expectUint(2000);
        block2.receipts[1].result.expectErr().expectUint(102); // err-bid-too-low
    }
});
