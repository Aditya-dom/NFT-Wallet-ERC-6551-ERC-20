import { ConnectButton, useConnectModal } from "@rainbow-me/rainbowkit";
import { useAccount } from "wagmi";
import Layout from "./layout.js";
import React, { useEffect, useState } from "react";
import {
  getNftsInfo,
  getErc6551Balances,
  walletAction,
} from "../components/config.js";

export default function WalletPage() {
  const { address, isConnected } = useAccount();
  const [nftinventory, getNftInventory] = useState([]);
  const [loadingState, setLoadingState] = useState(false);
  const [tokenbalances, getTokenBalances] = useState([]);
  const [activenftImage, setActiveNftImage] = useState("");
  const [activenftId, setActiveNftId] = useState("");
  const [activetoken, setActiveToken] = useState("");
  const [appbuttontxt, setAppButton] = useState("");
  const [tokenback, setTokenBack] = useState(null);
  const [activetokenbal, setActiveTokenBalance] = useState("");
  const [initmessage, setInitMessage] = useState("");
  const [nftwallet, setNftWallet] = useState(null);
  const [modalmsg, setModalMsg] = useState("");

  // New state for additional trading buttons
  const [limitOrderPrice, setLimitOrderPrice] = useState("");
  const [takeProfitPrice, setTakeProfitPrice] = useState("");
  const [stopLossPrice, setStopLossPrice] = useState("");
  const [activeTradeButton, setActiveTradeButton] = useState("");


  useEffect(() => {
    if (isConnected && address) {
      setInitMessage("Getting Inventory....");
      getInventory();
    } else {
      setLoadingState(false);
      setInitMessage("Please connect your wallet to view NFTs");
      // Reset states when wallet disconnects
      getNftInventory([]);
      getTokenBalances([]);
      setActiveNftImage("");
      setActiveNftId("");
      setActiveToken("");
      setAppButton("");
      setTokenBack(null);
      setActiveTokenBalance("");
      setNftWallet(null);

      // Reset new trade-related states
      setLimitOrderPrice("");
      setTakeProfitPrice("");
      setStopLossPrice("");
      setActiveTradeButton("");
    }
  }, [isConnected, address]);

  useEffect(() => {
    if (tokenbalances.length !== 0) {
      setActiveTokenBalance(tokenbalances[0].nativebal);
      setActiveToken(tokenbalances[0].nativetoken);
      setTokenBack(tokenbalances[0].nativetoken);
    }
  }, [tokenbalances]);

  const getInventory = async () => {
    try {
      let nfts = await getNftsInfo();
      getNftInventory(nfts);
      if (nfts.length > 0) {
        setActiveNftImage(nfts[0].nftimage);
        setActiveNftId(nfts[0].nftid);
        setNftWallet(nfts[0].nftwallet);
        setAppButton(nfts[0].buttontext);
        let tokenbalance = await getErc6551Balances(nfts[0].nftwallet);
        getTokenBalances(tokenbalance);
        setLoadingState(true);
      } else {
        setInitMessage("NFT's Not Found in Wallet!");
        setLoadingState(true);
      }
    } catch (error) {
      console.error("Error fetching inventory:", error);
      setInitMessage("Error fetching NFTs. Please try again.");
      setLoadingState(true);
    }
  };

  const changeNft = async (nftid, nftimage, wallet, buttontext) => {
    setActiveNftImage(nftimage);
    setActiveNftId(nftid);
    setNftWallet(wallet);
    setAppButton(buttontext);
    let tokenbalance = await getErc6551Balances(wallet);
    getTokenBalances(tokenbalance);
    setTokenBack(null);
  };

  const changeToken = async (tokenname, tokenbalance) => {
    setActiveTokenBalance(tokenbalance);
    setActiveToken(tokenname);
    setTokenBack(tokenname);
  };

  const openModal = async () => {
    const { Modal } = require("bootstrap");
    const myModal = new Modal("#msgmodal");
    myModal.show();
  };

  const closeModal = async () => {
    const { Modal } = require("bootstrap");
    let modal = Modal.getInstance(document.getElementById("msgmodal"));
    modal.hide();
  };

  const executeAction = async () => {
    let action = await walletAction(
      nftwallet,
      activetoken,
      appbuttontxt,
      activenftId
    );
    if (action == true) {
      if (appbuttontxt == "Withdraw") {
        setModalMsg("Withdraw in Progress... Standby");
      } else {
        setModalMsg("Creating NFT Wallet... Standby");
      }
      openModal();
      await new Promise((r) => setTimeout(r, 15000));
      closeModal();
      location.reload();
    }
  };

  const executeTradeAction = async (actionType) => {
    let price = "";
    switch (actionType) {
      case "Limit Order":
        price = limitOrderPrice;
        break;
      case "Take Profit":
        price = takeProfitPrice;
        break;
      case "Stop Loss":
        price = stopLossPrice;
        break;
      default:
        price = "";
    }

    let action = await walletAction(
      nftwallet,
      activetoken,
      actionType,
      activenftId,
      price
    );

    if (action == true) {
      setModalMsg(`${actionType} in Progress... Standby`);
      openModal();
      await new Promise((r) => setTimeout(r, 15000));
      closeModal();
      location.reload();
    }
  };

  if (!isConnected) {
    return (
      <Layout>
        <div className="container">
          <div className="row justify-content-center">
            <div className="col-md-6 text-center mt-5">
              <ConnectButton />
              <h4 className="mt-4">{initmessage}</h4>
            </div>
          </div>
        </div>
      </Layout>
    );
  }

  if (!loadingState) {
    return (
      <Layout>
        <div className="container">
          <div className="row justify-content-center">
            <div className="col-md-6 text-center mt-5">
              <h4>{initmessage}</h4>
            </div>
          </div>
        </div>
      </Layout>
    );
  }

  return (
    <>
      <div
        id="msgmodal"
        className="modal fade in"
        data-bs-keyboard="false"
        data-bs-backdrop="static"
        role="dialog"
      >
        <div className="modal-dialog modal-dialog-centered flex">
          <div
            className="modal-content modal-badge py-3"
            style={{ background: "#00000080" }}
          >
            <h5 className="mx-auto my-auto text-white">{modalmsg}</h5>
          </div>
        </div>
      </div>
      <div>
        <ConnectButton />
      </div>
      <Layout>
        <section className="nft-erc6551-details position-relative overflow-hidden ptb-100">
          <div className="container">
            <div className="erc6551-details rounded">
              <div className="row">
                <div className="col-lg-6">
                  <div className="pd-left">
                    <div className="pd-slider">
                      <div
                        id="controls"
                        className="carousel slide"
                        data-bs-ride="carousel"
                      >
                        <div className="carousel-inner">
                          <div className="carousel-item active">
                            <img
                              src={activenftImage}
                              className="img-fluid"
                              alt="product thumbnail"
                            />
                          </div>
                        </div>
                        <div className="carousel-inner">
                          {nftinventory.map((data, i) => (
                            <div key={i} className="carousel-item">
                              <img
                                src={data.nftimage}
                                className="img-fluid"
                                alt="product thumbnail"
                              />
                            </div>
                          ))}
                        </div>
                        <div className="carousel-indicators">
                          {nftinventory.map((data, i) => (
                            <button
                              key={i}
                              type="button"
                              onClick={() =>
                                changeNft(
                                  data.nftid,
                                  data.nftimage,
                                  data.nftwallet,
                                  data.buttontext
                                )
                              }
                              data-bs-target="#controls"
                              data-bs-slide-to="0"
                              className="active"
                              aria-current="true"
                              aria-label="Slide 1"
                            >
                              <img
                                src={data.nftimage}
                                className="img-fluid"
                                alt="nft "
                              />
                            </button>
                          ))}
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div className="col-lg-6">
                  <div className="pd-right">
                    <div
                      className="pd-title"
                      style={{ fontFamily: "SF Pro Display" }}
                    >
                      <h3 className="h3 text-white">
                        ERC-6551 NFT ERC-20 Wallet
                      </h3>
                      <h5
                        className="h6 margin-bottom-10"
                        style={{ fontFamily: "monospace", color: "#39FF14" }}
                      >
                        {nftwallet}
                      </h5>
                      <h5 className="h5 text-white">ERC-20 Tokens In NFT</h5>
                    </div>
                    <div className="pd-author-box">
                      <a
                        type="button"
                        className="single-author d-flex align-items-center"
                        onClick={() =>
                          changeToken(
                            tokenbalances?.[0]?.nativetoken,
                            tokenbalances?.[0]?.nativebal
                          )
                        }
                        style={{
                          backgroundColor:
                            tokenback === tokenbalances?.[0]?.nativetoken
                              ? "#6528e0"
                              : "transparent",
                        }}
                      >
                        <img
                          src="ethereum-eth.svg"
                          alt="nft creator"
                          width="70"
                          className="img-fluid"
                        />

                        <div className="author-info">
                          <span>{tokenbalances?.[0]?.nativetoken}</span>
                          <h4>{tokenbalances?.[0]?.nativebal}</h4>
                        </div>
                      </a>
                      <a
                        type="button"
                        className="single-author d-flex align-items-center"
                        onClick={() =>
                          changeToken(
                            tokenbalances?.[0]?.customtoken,
                            tokenbalances?.[0]?.custombal
                          )
                        }
                        style={{
                          backgroundColor:
                            tokenback === tokenbalances?.[0]?.customtoken
                              ? "#6528e0"
                              : "transparent",
                        }}
                      >
                        <img
                          src="usdt.svg"
                          alt="nft creator"
                          width="70"
                          className="img-fluid"
                        />

                        <div className="author-info">
                          <span>{tokenbalances?.[0]?.customtoken}</span>
                          <h4>{tokenbalances?.[0]?.custombal}</h4>
                        </div>
                      </a>
                    </div>
                    <div className="bid-amount margin-top-30">
                      <span className="text-white">Balance</span>
                      <h3 className="text-white">
                        {activetokenbal + " " + activetoken}{" "}
                      </h3>
                    </div>
                    <div className="pd-btns margin-top-20 d-flex flex-wrap">
                      <div className="primary-btn margin-right-10 mb-2">
                        <a
                          type="button"
                          onClick={() => executeTradeAction("Withdraw")}
                        >
                          <h5 className="my-auto">Withdraw</h5>
                        </a>
                      </div>

                      {/* Limit Order Button */}
                      <div className="primary-btn margin-right-10 mb-2">
                        <a
                          type="button"
                          onClick={() => {
                            setActiveTradeButton("Limit Order");
                          }}
                          style={{
                            backgroundColor:
                              activeTradeButton === "Limit Order"
                                ? "#6528e0"
                                : "transparent",
                          }}
                        >
                          <h5 className="my-auto">Limit Order</h5>
                        </a>
                        {activeTradeButton === "Limit Order" && (
                          <div className="mt-2">
                            <input
                              type="number"
                              placeholder="Enter Limit Price"
                              className="form-control text-white"
                              style={{ backgroundColor: "#333" }}
                              value={limitOrderPrice}
                              onChange={(e) =>
                                setLimitOrderPrice(e.target.value)
                              }
                            />
                            <button
                              className="btn btn-primary mt-2"
                              onClick={() => executeTradeAction("Limit Order")}
                            >
                              Confirm Limit Order
                            </button>
                          </div>
                        )}
                      </div>

                      {/* Take Profit Button */}
                      <div className="primary-btn margin-right-10 mb-2">
                        <a
                          type="button"
                          onClick={() => {
                            setActiveTradeButton("Take Profit");
                          }}
                          style={{
                            backgroundColor:
                              activeTradeButton === "Take Profit"
                                ? "#6528e0"
                                : "transparent",
                          }}
                        >
                          <h5 className="my-auto">Take Profit</h5>
                        </a>
                        {activeTradeButton === "Take Profit" && (
                          <div className="mt-2">
                            <input
                              type="number"
                              placeholder="Enter Take Profit Price"
                              className="form-control text-white"
                              style={{ backgroundColor: "#333" }}
                              value={takeProfitPrice}
                              onChange={(e) =>
                                setTakeProfitPrice(e.target.value)
                              }
                            />
                            <button
                              className="btn btn-primary mt-2"
                              onClick={() => executeTradeAction("Take Profit")}
                            >
                              Confirm Take Profit
                            </button>
                          </div>
                        )}
                      </div>

                      {/* Stop Loss Button */}
                      <div className="primary-btn margin-right-10 mb-2">
                        <a
                          type="button"
                          onClick={() => {
                            setActiveTradeButton("Stop Loss");
                          }}
                          style={{
                            backgroundColor:
                              activeTradeButton === " Stop Loss"
                                ? "#6528e0"
                                : "transparent",
                          }}
                        >
                          <h5 className="my-auto">Stop Loss</h5>
                        </a>
                        {activeTradeButton === "Stop Loss" && (
                          <div className="mt-2">
                            <input
                              type="number"
                              placeholder="Enter Stop Loss Price"
                              className="form-control text-white"
                              style={{ backgroundColor: "#333" }}
                              value={stopLossPrice}
                              onChange={(e) => setStopLossPrice(e.target.value)}
                            />
                            <button
                              className="btn btn-primary mt-2"
                              onClick={() => executeTradeAction("Stop Loss")}
                            >
                              Confirm Stop Loss
                            </button>
                          </div>
                        )}
                      </div>
                    </div>
                    <div className="pd-tab">
                      <ul className="nav nav-tabs">
                        <li>
                          <button
                            className="active"
                            data-bs-toggle="tab"
                            data-bs-target="#details"
                          >
                            NFT Details
                          </button>
                        </li>
                      </ul>
                      <div className="tab-content">
                        <div className="tab-pane active fade show" id="details">
                          <h3>ID: {activenftId}</h3>
                          <h5>
                            NFT Collection with TokenBound ERC-6551 Tutorial
                          </h5>
                          <img
                            src="https://raw.githubusercontent.com/net2devcrypto/misc/main/net2dev-sociallogo.png"
                            width="150"
                            style={{ opacity: "0.6" }}
                          />
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </section>
      </Layout>
    </>
  );
}
// import { ConnectButton, useConnectModal } from "@rainbow-me/rainbowkit";
// import { useAccount } from "wagmi";
// import Layout from "./layout.js";
// import React, { useEffect, useState } from "react";
// import {
//   getNftsInfo,
//   getErc6551Balances,
//   walletAction,
// } from "../components/config.js";

// export default function WalletPage() {
//   const { address, isConnected } = useAccount();
//   const [nftinventory, getNftInventory] = useState([]);
//   const [loadingState, setLoadingState] = useState(false);
//   const [tokenbalances, getTokenBalances] = useState([]);
//   const [activenftImage, setActiveNftImage] = useState("");
//   const [activenftId, setActiveNftId] = useState("");
//   const [activetoken, setActiveToken] = useState("");
//   const [appbuttontxt, setAppButton] = useState("");
//   const [tokenback, setTokenBack] = useState(null);
//   const [activetokenbal, setActiveTokenBalance] = useState("");
//   const [initmessage, setInitMessage] = useState("");
//   const [nftwallet, setNftWallet] = useState(null);
//   const [modalmsg, setModalMsg] = useState("");

//   useEffect(() => {
//     if (isConnected && address) {
//       setInitMessage("Getting Inventory....");
//       getInventory();
//     } else {
//       setLoadingState(false);
//       setInitMessage("Please connect your wallet to view NFTs");
//       // Reset states when wallet disconnects
//       getNftInventory([]);
//       getTokenBalances([]);
//       setActiveNftImage("");
//       setActiveNftId("");
//       setActiveToken("");
//       setAppButton("");
//       setTokenBack(null);
//       setActiveTokenBalance("");
//       setNftWallet(null);
//     }
//   }, [isConnected, address]);

//   useEffect(() => {
//     if (tokenbalances.length !== 0) {
//       setActiveTokenBalance(tokenbalances[0].nativebal);
//       setActiveToken(tokenbalances[0].nativetoken);
//       setTokenBack(tokenbalances[0].nativetoken);
//     }
//   }, [tokenbalances]);

//   const getInventory = async () => {
//     try {
//       let nfts = await getNftsInfo();
//       getNftInventory(nfts);
//       if (nfts.length > 0) {
//         setActiveNftImage(nfts[0].nftimage);
//         setActiveNftId(nfts[0].nftid);
//         setNftWallet(nfts[0].nftwallet);
//         setAppButton(nfts[0].buttontext);
//         let tokenbalance = await getErc6551Balances(nfts[0].nftwallet);
//         getTokenBalances(tokenbalance);
//         setLoadingState(true);
//       } else {
//         setInitMessage("NFT's Not Found in Wallet!");
//         setLoadingState(true);
//       }
//     } catch (error) {
//       console.error("Error fetching inventory:", error);
//       setInitMessage("Error fetching NFTs. Please try again.");
//       setLoadingState(true);
//     }
//   };

//   const changeNft = async (nftid, nftimage, wallet, buttontext) => {
//     setActiveNftImage(nftimage);
//     setActiveNftId(nftid);
//     setNftWallet(wallet);
//     setAppButton(buttontext);
//     let tokenbalance = await getErc6551Balances(wallet);
//     getTokenBalances(tokenbalance);
//     setTokenBack(null);
//   };

//   const changeToken = async (tokenname, tokenbalance) => {
//     setActiveTokenBalance(tokenbalance);
//     setActiveToken(tokenname);
//     setTokenBack(tokenname);
//   };

//   const openModal = async () => {
//     const { Modal } = require("bootstrap");
//     const myModal = new Modal("#msgmodal");
//     myModal.show();
//   };

//   const closeModal = async () => {
//     const { Modal } = require("bootstrap");
//     let modal = Modal.getInstance(document.getElementById("msgmodal"));
//     modal.hide();
//   };

//   const executeAction = async () => {
//     let action = await walletAction(
//       nftwallet,
//       activetoken,
//       appbuttontxt,
//       activenftId
//     );
//     if (action == true) {
//       if (appbuttontxt == "Withdraw") {
//         setModalMsg("Withdraw in Progress... Standby");
//       } else {
//         setModalMsg("Creating NFT Wallet... Standby");
//       }
//       openModal();
//       await new Promise((r) => setTimeout(r, 15000));
//       closeModal();
//       location.reload();
//     }
//   };

//   if (!isConnected) {
//     return (
//       <Layout>
//         <div className="container">
//           <div className="row justify-content-center">
//             <div className="col-md-6 text-center mt-5">
//               <ConnectButton />
//               <h4 className="mt-4">{initmessage}</h4>
//             </div>
//           </div>
//         </div>
//       </Layout>
//     );
//   }

//   if (!loadingState) {
//     return (
//       <Layout>
//         <div className="container">
//           <div className="row justify-content-center">
//             <div className="col-md-6 text-center mt-5">
//               <h4>{initmessage}</h4>
//             </div>
//           </div>
//         </div>
//       </Layout>
//     );
//   }

//   return (
//     <>
//       <div
//         id="msgmodal"
//         className="modal fade in"
//         data-bs-keyboard="false"
//         data-bs-backdrop="static"
//         role="dialog"
//       >
//         <div className="modal-dialog modal-dialog-centered flex">
//           <div
//             className="modal-content modal-badge py-3"
//             style={{ background: "#00000080" }}
//           >
//             <h5 className="mx-auto my-auto text-white">{modalmsg}</h5>
//           </div>
//         </div>
//       </div>
//       <div>
//         <ConnectButton />
//       </div>
//       <Layout>
//         <section className="nft-erc6551-details position-relative overflow-hidden ptb-100">
//           <div className="container">
//             <div className="erc6551-details rounded">
//               <div className="row">
//                 <div className="col-lg-6">
//                   <div className="pd-left">
//                     <div className="pd-slider">
//                       <div
//                         id="controls"
//                         className="carousel slide"
//                         data-bs-ride="carousel"
//                       >
//                         <div className="carousel-inner">
//                           <div className="carousel-item active">
//                             <img
//                               src={activenftImage}
//                               className="img-fluid"
//                               alt="product thumbnail"
//                             />
//                           </div>
//                         </div>
//                         <div className="carousel-inner">
//                           {nftinventory.map((data, i) => (
//                             <div key={i} className="carousel-item">
//                               <img
//                                 src={data.nftimage}
//                                 className="img-fluid"
//                                 alt="product thumbnail"
//                               />
//                             </div>
//                           ))}
//                         </div>
//                         <div className="carousel-indicators">
//                           {nftinventory.map((data, i) => (
//                             <button
//                               key={i}
//                               type="button"
//                               onClick={() =>
//                                 changeNft(
//                                   data.nftid,
//                                   data.nftimage,
//                                   data.nftwallet,
//                                   data.buttontext
//                                 )
//                               }
//                               data-bs-target="#controls"
//                               data-bs-slide-to="0"
//                               className="active"
//                               aria-current="true"
//                               aria-label="Slide 1"
//                             >
//                               <img
//                                 src={data.nftimage}
//                                 className="img-fluid"
//                                 alt="nft "
//                               />
//                             </button>
//                           ))}
//                         </div>
//                       </div>
//                     </div>
//                   </div>
//                 </div>
//                 <div className="col-lg-6">
//                   <div className="pd-right">
//                     <div
//                       className="pd-title"
//                       style={{ fontFamily: "SF Pro Display" }}
//                     >
//                       <h3 className="h3 text-white">
//                         ERC-6551 NFT ERC-20 Wallet
//                       </h3>
//                       <h5
//                         className="h6 margin-bottom-10"
//                         style={{ fontFamily: "monospace", color: "#39FF14" }}
//                       >
//                         {nftwallet}
//                       </h5>
//                       <h5 className="h5 text-white">ERC-20 Tokens In NFT</h5>
//                     </div>
//                     <div className="pd-author-box">
//                       <a
//                         type="button"
//                         className="single-author d-flex align-items-center"
//                         onClick={() =>
//                           changeToken(
//                             tokenbalances[0].nativetoken,
//                             tokenbalances[0].nativebal
//                           )
//                         }
//                         style={{
//                           backgroundColor:
//                             tokenback === tokenbalances[0].nativetoken
//                               ? "#6528e0"
//                               : "transparent",
//                         }}
//                       >
//                         <img
//                           src="ethereum-eth.svg"
//                           alt="nft creator"
//                           width="70"
//                           className="img-fluid"
//                         />

//                         <div className="author-info">
//                           <span>{tokenbalances[0].nativetoken}</span>
//                           <h4>{tokenbalances[0].nativebal}</h4>
//                         </div>
//                       </a>
//                       <a
//                         type="button"
//                         className="single-author d-flex align-items-center"
//                         onClick={() =>
//                           changeToken(
//                             tokenbalances[0].customtoken,
//                             tokenbalances[0].custombal
//                           )
//                         }
//                         style={{
//                           backgroundColor:
//                             tokenback === tokenbalances[0].customtoken
//                               ? "#6528e0"
//                               : "transparent",
//                         }}
//                       >
//                         <img
//                           src="usdt.svg"
//                           alt="nft creator"
//                           width="70"
//                           className="img-fluid"
//                         />

//                         <div className="author-info">
//                           <span>{tokenbalances[0].customtoken}</span>
//                           <h4>{tokenbalances[0].custombal}</h4>
//                         </div>
//                       </a>
//                     </div>
//                     <div className="bid-amount margin-top-30">
//                       <span className="text-white">Balance</span>
//                       <h3 className="text-white">
//                         {activetokenbal + " " + activetoken}{" "}
//                       </h3>
//                     </div>
//                     <div className="pd-btns margin-top-20">
//                       <div className="primary-btn margin-right-10">
//                         <a type="button" onClick={executeAction}>
//                           <h5 className="my-auto">{appbuttontxt}</h5>
//                         </a>
//                       </div>
//                     </div>
//                     <div className="pd-tab">
//                       <ul className="nav nav-tabs">
//                         <li>
//                           <button
//                             className="active"
//                             data-bs-toggle="tab"
//                             data-bs-target="#details"
//                           >
//                             NFT Details
//                           </button>
//                         </li>
//                       </ul>
//                       <div className="tab-content">
//                         <div className="tab-pane active fade show" id="details">
//                           <h3>ID: {activenftId}</h3>
//                           <h5>
//                             NFT Collection with TokenBound ERC-6551 Tutorial
//                           </h5>
//                           <img
//                             src="https://raw.githubusercontent.com/net2devcrypto/misc/main/net2dev-sociallogo.png"
//                             width="150"
//                             style={{ opacity: "0.6" }}
//                           />
//                         </div>
//                       </div>
//                     </div>
//                   </div>
//                 </div>
//               </div>
//             </div>
//           </div>
//         </section>
//       </Layout>
//     </>
//   );
// }
