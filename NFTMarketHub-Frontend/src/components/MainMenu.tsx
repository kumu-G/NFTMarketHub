import { ConnectButton } from "@rainbow-me/rainbowkit";
import React from "react";
import { Link } from "react-router-dom";

const MainMenu: React.FC = () => {
    return (
        <header className="w-full">
            <div className="h-16 w-full bg-emerald-600">
                <nav className="flex items-center justify-between h-full w-full px-4">
                    <h1 className="text-3xl font-bold text-white mr-14">
                        Welcome to NFTMarketHub
                    </h1>
                    <ul className="flex space-x-8">
                        <li>
                            <Link to={"/"} className="text-white font-extrabold text-xl hover:text-gray-300">Home</Link>
                        </li>
                        <li>
                            <Link to="/erc20" className="text-white font-extrabold text-xl hover:text-gray-300">ERC20</Link>
                        </li>
                        <li>
                            <Link to="/nft" className="text-white font-extrabold text-xl hover:text-gray-300">NFT</Link>
                        </li>
                        <li>
                            <Link to="/market" className="text-white font-extrabold text-xl hover:text-gray-300">Market</Link>
                        </li>
                    </ul>
                    <div className="flex-grow flex justify-end">
                        <div className="h-full flex items-center scale-125">
                            <ConnectButton />
                        </div>
                    </div>
                </nav>
            </div>
        </header>
    );
};

export default MainMenu;
