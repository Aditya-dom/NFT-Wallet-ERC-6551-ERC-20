import Head from "next/head";
import "bootstrap/dist/css/bootstrap.min.css";
import Script from "next/script";
import { Fragment, useState } from "react";
import "../assets/scss/main.scss";
import "swiper/css";
import "react-modal-video/scss/modal-video.scss";
import "@rainbow-me/rainbowkit/styles.css";
import { getDefaultConfig, RainbowKitProvider } from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import {
  sepolia,
  goerli,
  polygonMumbai,
  arbitrumSepolia,
  optimismSepolia,
  baseSepolia,
} from "wagmi/chains";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";

// Custom RPC configuration for Mumbai testnet
const mumbaiCustomRpc = {
  ...polygonMumbai,
  rpcUrls: {
    default: {
      http: ["https://rpc-mumbai.maticvigil.com"],
    },
    public: {
      http: ["https://rpc-mumbai.maticvigil.com"],
    },
  },
};

const config = getDefaultConfig({
  appName: "WEB3-WALLET-PROVIDERS",
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID,
  chains: [
    sepolia, // Ethereum testnet
    goerli, // Ethereum testnet
    mumbaiCustomRpc, // Polygon testnet
    arbitrumSepolia, // Arbitrum testnet
    optimismSepolia, // Optimism testnet
    baseSepolia, // Base testnet
  ],
  ssr: true,
  initialChain: sepolia, // Default Network
});

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchOnWindowFocus: false,
      retry: 2,
      staleTime: 30000,
    },
  },
});

function MyApp({ Component, pageProps }) {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider modalSize="compact" showRecentTransactions={true}>
          <Fragment>
            <Head>
              <meta charSet="utf-8" />
              <meta
                name="viewport"
                content="minimum-scale=1, initial-scale=1, width=device-width, shrink-to-fit=no, viewport-fit=cover"
              />
              <title>WEB3-WALLET-PROVIDERS</title>
              <meta name="description" content="#" />
            </Head>

            {/* Bootstrap JavaScript */}
            <Script
              src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"
              integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p"
              crossOrigin="anonymous"
              strategy="afterInteractive"
            />

            {/* layout component goes here */}
            <main className="main-wrapper">
              <Component {...pageProps} />
            </main>

            {/* global components goes here */}
          </Fragment>
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
}

export default MyApp;

// UNCOMMENT THE BELOW CODE FOR CONNECTING WALLETS TO MAIN NET

// import Head from "next/head";
// import "bootstrap/dist/css/bootstrap.min.css";
// import Script from "next/script";
// import { Fragment } from "react";
// import "../assets/scss/main.scss";
// import "swiper/css";
// import "react-modal-video/scss/modal-video.scss";
// import "@rainbow-me/rainbowkit/styles.css";
// import { getDefaultConfig, RainbowKitProvider } from "@rainbow-me/rainbowkit";
// import { WagmiProvider } from "wagmi";
// import { mainnet, polygon, optimism, arbitrum, base } from "wagmi/chains";
// import { QueryClientProvider, QueryClient } from "@tanstack/react-query";

// const config = getDefaultConfig({
//   appName: "My RainbowKit App",
//   projectId: "YOUR_PROJECT_ID",
//   chains: [mainnet, polygon, optimism, arbitrum, base],
//   ssr: true, // If your dApp uses server side rendering (SSR)
// });

// // Create a new QueryClient instance
// const queryClient = new QueryClient();

// function MyApp({ Component, pageProps }) {
//   return (
//     <WagmiProvider config={config}>
//       <QueryClientProvider client={queryClient}>
//         <RainbowKitProvider>
//           <Fragment>
//             <Script
//               src="https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"
//               integrity="sha384-ka7Sk0Gln4gmtz2MlQnikT1wXgYsOg+OMhuP+IlRH9sENBO0LRn5q+8nbTov4+1p"
//               crossorigin="anonymous"
//             ></Script>
//             <Head>
//               <meta
//                 name="viewport"
//                 content="minimum-scale=1, initial-scale=1, width=device-width, shrink-to-fit=no, viewport-fit=cover"
//               />
//             </Head>
//             <Component {...pageProps} />
//           </Fragment>
//         </RainbowKitProvider>
//       </QueryClientProvider>
//     </WagmiProvider>
//   );
// }

// export default MyApp;
