import { createPublicClient, createWalletClient, custom, http } from 'viem'
import { mainnet, sepolia } from 'viem/chains'

export const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(),
})

// eg: Metamask
export const walletClient = createWalletClient({
    chain: sepolia,
    transport: custom(window.ethereum!),
})

