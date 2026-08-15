package model

const (
	_ = iota
	TaskTypeHTTPGet
	TaskTypeICMPPing
	TaskTypeTCPPing
	// Reserved: command execution is disabled in the hardened Agent.
	TaskTypeCommand
	// Reserved: web terminal is disabled in the hardened Agent.
	TaskTypeTerminal
	TaskTypeUpgrade
	TaskTypeKeepalive
	// Reserved: gRPC web terminal is disabled in the hardened Agent.
	TaskTypeTerminalGRPC
	TaskTypeNAT
	TaskTypeReportHostInfoDeprecated
	// Reserved: file manager is disabled in the hardened Agent.
	TaskTypeFM
	TaskTypeReportConfig
	TaskTypeApplyConfig
	TaskTypeServerTransferApply
	// Reserved: MCP command execution is disabled in the hardened Agent.
	TaskTypeExec
	// Reserved: MCP filesystem operations are disabled in the hardened Agent.
	TaskTypeFsList
	TaskTypeFsRead
	TaskTypeFsWrite
	TaskTypeFsDelete
	TaskTypeFsTransfer
)

type TaskNAT struct {
	StreamID string
	Host     string
}
