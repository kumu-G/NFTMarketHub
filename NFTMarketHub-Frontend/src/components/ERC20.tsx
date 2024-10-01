import { publicClient } from "@/client";
import { MyERC20TokenAbi } from "@abi/MyERC20TokenAbi";
import { Address, encodeAbiParameters, parseAbiParameters, toFunctionSelector } from "viem";
import { useAccount } from "wagmi";

const ERC20Token = import.meta.env
    .VITE_MyERC20Token_Contract_Address as Address;
if (!ERC20Token) {
    throw new Error("Missing MyERC20Token_Contract address");
}

const totalSupply = await publicClient.readContract({
    address: ERC20Token,
    abi: MyERC20TokenAbi,
    functionName: "totalSupply",
});

console.log(totalSupply);

// const encodedData = encodeAbiParameters(
//     parseAbiParameters("string x, uint y, bool z"),
//     ["wagmi", 420n, true]
// );

// console.log(encodedData, "encoded data");
// const selector_1 = toFunctionSelector("function transfer(address,uint256)");
// const selector_2 = toFunctionSelector("function transfer(address,uint256)");
// console.log(selector_1, selector_2, "selectors");

const ERC20 = async () => {
    const { address, isConnected } = useAccount();
    // const data = await publicClient.readContract({
    //     address: ERC20Token,
    //     abi: MyERC20TokenAbi,
    //     functionName: 'balanceOf',
    //     args: [address as Address]
    // })

    if (!isConnected) {
        return <div>Please connect your wallet</div>;
    }
    return (
        <div>
            <h1>ERC20</h1>
            <p>Address: {address}</p>
            {/* <p>data: {data.toLocaleString()}</p> */}
            <p>
                Total Supply:{" "}
                {totalSupply !== null ? totalSupply.toLocaleString() : "Loading..."}
            </p>
        </div>
    );
};

export default ERC20;
