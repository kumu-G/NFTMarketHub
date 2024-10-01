import Layout from "@components/Layout";
import HomePage from "@pages/HomePage";
import ERC20Page from "@pages/ERC20Page";
import NFTPage from "@pages/NFTPage";
import MarketPage from "@pages/MarketPage";
import { Route, Routes } from "react-router-dom";


const App = () => {

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<HomePage />} />
        <Route path="/erc20" element={<ERC20Page />} />
        <Route path="/nft" element={<NFTPage />} />
        <Route path="/market" element={<MarketPage />} />
        <Route path="*" element={<h1>404 NOT FOUND</h1>} />

      </Routes>
    </Layout>
  );
};

export default App;
