import { useAccount, useReadContract } from 'wagmi'

const Home = () => {
    const { address, isConnected } = useAccount();

    return (
        <div>
            <h1>Home</h1>
            <p>{address}</p>
            <p>{isConnected ? "Connected" : "Not Connected"}</p>

            {/* Displaying listed NFTs */}
            <div>
                <h2>Listed NFTs</h2>
                {/* Add your logic to fetch and display NFTs here */}
                {/* Example static content */}
                <ul>
                    <li>NFT 1</li>
                    <li>NFT 2</li>
                    <li>NFT 3</li>
                </ul>
            </div>
        </div>
    );
};

export default Home;
