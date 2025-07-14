package client

import (
	"context"
	"github.com/ava-labs/avalanchego/ids"
	"github.com/ava-labs/avalanchego/network/peer"
	"github.com/ava-labs/avalanchego/utils/json"
	"math/big"
	"strings"

	"github.com/ava-labs/avalanchego/api/info"
	"github.com/ava-labs/avalanchego/utils/rpc"
	ethtypes "github.com/ava-labs/coreth/core/types"
	"github.com/ava-labs/coreth/interfaces"
	ethcommon "github.com/ethereum/go-ethereum/common"
)

// Interface compliance
var _ Client = &client{}

type Client interface {
	IsBootstrapped(context.Context, string, ...rpc.Option) (bool, error)
	ChainID(context.Context) (*big.Int, error)
	BlockByHash(context.Context, ethcommon.Hash) (*ethtypes.Block, error)
	BlockByNumber(context.Context, *big.Int) (*ethtypes.Block, error)
	HeaderByHash(context.Context, ethcommon.Hash) (*ethtypes.Header, error)
	HeaderByNumber(context.Context, *big.Int) (*ethtypes.Header, error)
	TransactionByHash(context.Context, ethcommon.Hash) (*ethtypes.Transaction, bool, error)
	TransactionReceipt(context.Context, ethcommon.Hash) (*ethtypes.Receipt, error)
	TraceTransaction(context.Context, string) (*Call, []*FlatCall, error)
	TraceBlockByHash(context.Context, string) ([]*Call, [][]*FlatCall, error)
	SendTransaction(context.Context, *ethtypes.Transaction) error
	BalanceAt(context.Context, ethcommon.Address, *big.Int) (*big.Int, error)
	NonceAt(context.Context, ethcommon.Address, *big.Int) (uint64, error)
	SuggestGasPrice(context.Context) (*big.Int, error)
	EstimateGas(context.Context, interfaces.CallMsg) (uint64, error)
	TxPoolContent(context.Context) (*TxPoolContent, error)
	GetNetworkName(context.Context, ...rpc.Option) (string, error)
	Peers(context.Context, ...rpc.Option) ([]info.Peer, error)
	// Peers_v1_11 enables info.peers RPC call compatible with v1.11.
	// Once the dependencies are upgraded, this should be replaced with Peers.
	Peers_v1_11(context.Context, []ids.NodeID, ...rpc.Option) ([]Peer_v1_11, error)
	GetContractInfo(ethcommon.Address, bool) (string, uint8, error)
	CallContract(context.Context, interfaces.CallMsg, *big.Int) ([]byte, error)
}

type clientFix struct {
	requester rpc.EndpointRequester
}

func newClientFix(uri string) *clientFix {
	return &clientFix{
		requester: rpc.NewEndpointRequester(
			uri+"/ext/info",
			"info",
		),
	}
}

type Peer_v1_11 struct {
	peer.Info

	Benched []string `json:"benched"`
}

type PeersReply_v1_11 struct {
	// Number of elements in [Peers]
	NumPeers json.Uint64 `json:"numPeers"`
	// Each element is a peer
	Peers []Peer_v1_11 `json:"peers"`
}

func (cf *clientFix) Peers_v1_11(ctx context.Context, nodeIDs []ids.NodeID, options ...rpc.Option) ([]Peer_v1_11, error) {
	res := &PeersReply_v1_11{}
	err := cf.requester.SendRequest(ctx, "peers", &info.PeersArgs{
		NodeIDs: nodeIDs,
	}, res, options...)
	return res.Peers, err
}

type client struct {
	info.Client
	*clientFix
	*EthClient
	*ContractClient
}

// NewClient returns a new client for Flare APIs
func NewClient(ctx context.Context, endpoint string) (Client, error) {
	endpoint = strings.TrimSuffix(endpoint, "/")

	eth, err := NewEthClient(ctx, endpoint)
	if err != nil {
		return nil, err
	}

	return client{
		Client:         info.NewClient(endpoint),
		clientFix:      newClientFix(endpoint),
		EthClient:      eth,
		ContractClient: NewContractClient(eth.Client),
	}, nil
}
