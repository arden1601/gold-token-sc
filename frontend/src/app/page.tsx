"use client";

import { useState } from "react";
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from "wagmi";
import { GOLD_PRICE_ORACLE_ABI, GOLD_TOKEN_ABI, GOLDPRICE_CONTRACT_ADDRESS, GOLDTOKEN_CONTRACT_ADDRESS } from "@/helper/contracts";
import { parseEther, formatEther } from "viem";
import { ConnectButton } from "@rainbow-me/rainbowkit";
// --- Main Page Component ---
export default function Home() {
  const { address, isConnected } = useAccount();

  return (
    <div className="container">
      <header className="header">
        <h1>Gold Token dApp</h1>
        <ConnectButton />
      </header>

      {!isConnected ? (
        <p className="connect-prompt">Please connect your wallet to continue.</p>
      ) : (
        <main className="main-grid">
          <ContractData />
          <WalletInfo address={address as `0x${string}`} />
          <CustodianActions />
          <WithDrawGold address={address as `0x${string}`} />
        </main>
      )}
    </div>
  );
}

// Components

function ContractData() {
  const { data: goldPrice } = useReadContract({
    address: GOLDPRICE_CONTRACT_ADDRESS,
    abi: GOLD_PRICE_ORACLE_ABI,
    functionName: "getLatestPrice",
  });

  const { data: totalSupply } = useReadContract({
    address: GOLDTOKEN_CONTRACT_ADDRESS,
    abi: GOLD_TOKEN_ABI,
    functionName: "totalSupply",
  });

  const formattedPrice = goldPrice ? `$${(Number(goldPrice) / 1e8).toFixed(2)}` : "Loading...";
  const formattedSupply = totalSupply ? `${formatEther(totalSupply as bigint)} GLD` : "Loading...";

  return (
    <div className="card">
      <h2>Live Contract Data</h2>
      <p><strong>Gold Price (XAU/USD):</strong> {formattedPrice}</p>
      <p><strong>Total GLD Supply:</strong> {formattedSupply}</p>
    </div>
  );
}

function WithDrawGold({ address }: { address: `0x${string}` }){
  const { data: hash, writeContract, isPending } = useWriteContract();
  const [amount, setAmount] = useState("");

  async function withdrawGold() {
    if (!address) return alert("Please connect your wallet.");
    writeContract({
      address: GOLDTOKEN_CONTRACT_ADDRESS,
      abi: GOLD_TOKEN_ABI,
      functionName: 'withdraw',
      args: [amount],
    });

  }

  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash });

  return (
    <div className="card">
      <h2>Withdraw Gold</h2>
      <input
        type="number"
        placeholder="Amount to Withdraw"
        value={parseInt(amount)/1e18}
        onChange={(e) => setAmount(String(parseInt(e.target.value)*1e18))}
        required
      />
      <button onClick={withdrawGold} disabled={isPending}>
        {isPending ? 'Confirming...' : 'Withdraw Gold'}
      </button>
      {hash && <p>Transaction Hash: {hash.slice(0,10)}...</p>}
      {isConfirming && <p>Waiting for confirmation...</p>}
      {isConfirmed && <p>Transaction confirmed!</p>}
    </div>
  );

}

function WalletInfo({ address }: { address: `0x${string}` }) {
  const { data: balance } = useReadContract({
    address: GOLDTOKEN_CONTRACT_ADDRESS,
    abi: GOLD_TOKEN_ABI,
    functionName: "balanceOf",
    args: [address],
  });

  const formattedBalance = balance ? `${formatEther(balance as bigint)} GLD` : "Loading...";

  return (
    <div className="card">
      <h2>Your Wallet</h2>
      <p><strong>Address:</strong> {`${address.slice(0, 6)}...${address.slice(-4)}`}</p>
      <p><strong>Your GLD Balance:</strong> {formattedBalance}</p>
    </div>
  );
}

function CustodianActions() {
    const { address } = useAccount();
    const [mintRecipient, setMintRecipient] = useState("");
    const [mintAmount, setMintAmount] = useState("");
    const { data: hash, writeContract, isPending, error } = useWriteContract();
    const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash });

    // Check if the connected user is the owner
    const { data: ownerAddress } = useReadContract({
        address: GOLDTOKEN_CONTRACT_ADDRESS,
        abi: GOLD_TOKEN_ABI,
        functionName: "owner",
    });

    const isOwner = address === ownerAddress;

    async function submitMint(e: React.FormEvent<HTMLFormElement>) {
        e.preventDefault();
        if (!mintRecipient || !mintAmount) return alert("Please fill in all fields.");
        writeContract({
            address: GOLDTOKEN_CONTRACT_ADDRESS,
            abi: GOLD_TOKEN_ABI,
            functionName: 'mint',
            args: [mintRecipient as `0x${string}`, parseEther(mintAmount)],
        });
    }

    if (!isOwner) {
        return (
            <div className="card">
                <h2>Custodian Actions</h2>
                <p>You are not the custodian/owner of this contract.</p>
            </div>
        );
    }

    return (
        <div className="card">
            <h2>Custodian Actions: Mint GLD</h2>
            <form onSubmit={submitMint}>
                 <input
                    name="recipient"
                    placeholder="Recipient Address (0x...)"
                    value={mintRecipient}
                    onChange={(e) => setMintRecipient(e.target.value)}
                    required
                />
                <input
                    name="amount"
                    placeholder="Amount to Mint"
                    value={mintAmount}
                    onChange={(e) => setMintAmount(e.target.value)}
                    required
                />
                <button type="submit" disabled={isPending}>
                    {isPending ? 'Confirming...' : 'Mint Tokens'}
                </button>
            </form>
            {hash && <p>Transaction Hash: {hash.slice(0,10)}...</p>}
            {isConfirming && <p>Waiting for confirmation...</p>}
            {isConfirmed && <p>Transaction confirmed!</p>}
            {error && <p>Error: {error.message}</p>}
        </div>
    );
}