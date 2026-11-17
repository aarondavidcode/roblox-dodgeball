-- Studio setup: BallPhysicsClient.md
-- Client singleton for BallPhysics ownership replication (required for client-owned ball sim).

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BallPhysics = require(ReplicatedStorage:WaitForChild("BallPhysics"))
BallPhysics.new()
