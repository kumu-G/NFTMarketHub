import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import {
    arbitrum,
    base,
    mainnet,
    optimism,
    polygon,
    sepolia,
} from 'wagmi/chains';

export const config = getDefaultConfig({
    appName: 'RainbowKit App',
    projectId: '399d42381c9453d2dafc7f46a015dfba',
    chains: [
        mainnet,
        polygon,
        optimism,
        arbitrum,
        base,
        ...(import.meta.env.VITE_PUBLIC_ENABLE_TESTNETS === 'true' ? [sepolia] : []),
    ],
    ssr: true,
});
