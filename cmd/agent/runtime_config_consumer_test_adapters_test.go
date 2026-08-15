package main

import (
	"context"

	"github.com/nezhahq/agent/model"
	pb "github.com/nezhahq/agent/proto"
)

func setTestRuntimeConfig(config model.AgentConfig) *model.AgentConfig {
	agentConfig = config
	return publishRuntimeConfig(config)
}

func loadLegacyHandlerTestConfig() *model.AgentConfig {
	return publishRuntimeConfig(agentConfig)
}

func handleUpgradeTask(task *pb.Task, result *pb.TaskResult) {
	config := loadLegacyHandlerTestConfig()
	handleUpgradeTaskWithConfig(updateConfigTupleFrom(config), taskFeatureGatesFrom(config))
}

func handleTcpPingTask(task *pb.Task, result *pb.TaskResult) {
	handleTcpPingTaskWithConfig(taskFeatureGatesFrom(loadLegacyHandlerTestConfig()), task, result)
}

func handleIcmpPingTask(task *pb.Task, result *pb.TaskResult) {
	handleIcmpPingTaskWithConfig(taskFeatureGatesFrom(loadLegacyHandlerTestConfig()), task, result)
}

func handleHttpGetTask(task *pb.Task, result *pb.TaskResult) {
	handleHttpGetTaskWithConfig(taskFeatureGatesFrom(loadLegacyHandlerTestConfig()), task, result)
}

func handleReportConfigTask(result *pb.TaskResult) {
	handleReportConfigTaskWithConfig(loadLegacyHandlerTestConfig(), result)
}

func handleNATTask(task *pb.Task) {
	handleNATTaskWithConfig(context.Background(), taskFeatureGatesFrom(loadLegacyHandlerTestConfig()), task)
}
