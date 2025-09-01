---
title: Logout Issue
tags: Rubric
abbrlink: 64160
date: 2025-07-31 10:22:47
---

# Logout Issues

## Logout Issues

Before describing the logout issues, let's define two concepts:

- logout: Clicking the logout button to exit robrix by interacting with matrix
- shut down: Clicking x to exit the robrix process

### The Earliest 'Dead-Pool' Issue in Logout

[https://github.com/project-robius/robrix/pull/432#discussion\\_r2171202111](https://github.com/project-robius/robrix/pull/432#discussion%5C%5C_r2171202111)
The commit hash at that time was e1f80ea
The key code was as follows:

```rust
/// Logs out the current user and prepares the application for a new login session.
///
/// Performs server-side logout, cleans up client state, closes all tabs,
/// and restarts the Matrix runtime. Reports success or failure via LoginAction.
///
/// # Parameters
/// - is_desktop - Boolean indicating if the current UI mode is desktop (true) or mobile (false).
///
/// # Returns
/// - Ok(()) - Logout succeeded (possibly with cleanup warnings)
/// - Err(...) - Logout failed with detailed error
async fn logout_and_refresh(is_desktop :bool) -> Result<()> {
    // Collect all errors encountered during the logout process
    let mut errors = Vec::new();
    log!("Starting logout process...");
    let Some(client) = get_client() else {
        let error_msg = "Logout failed: No active client found";
        log!("Error: {}", error_msg);
        Cx::post_action(LogoutAction::LogoutFailure(error_msg.to_string()));
        return Err(anyhow::anyhow!(error_msg));
    };
    if !client.matrix_auth().logged_in() {
        let error_msg = "Client not logged in, skipping server-side logout";
        log!("Error: {}", error_msg);
        Cx::post_action(LogoutAction::LogoutFailure(error_msg.to_string()));
        return Err(anyhow::anyhow!(error_msg));
    }

    get_sync_service().unwrap().stop().await;

    log!("Performing server-side logout...");
    match tokio::time::timeout(tokio::time::Duration::from_secs(5), client.matrix_auth().logout()).await {
        Ok(Ok(_)) => {
            log!("Server-side logout successful.")
        },
        Ok(Err(e)) => {
            let error_msg = format!("Server-side logout failed: {}. Please try again later", e);
            log!("Error :{}", error_msg);
            Cx::post_action(LogoutAction::LogoutFailure(error_msg.to_string()));
            return Err(anyhow::anyhow!(error_msg));
        },
        Err(_) => {
            let error_msg = "Server-side logout timed out after 5 seconds. Please try again later";
            log!("Error: {}", error_msg);
            Cx::post_action(LogoutAction::LogoutFailure(error_msg.to_string()));
            return Err(anyhow::anyhow!(error_msg));
        },
    }

    // Clean up client state and caches
    log!("Cleaning up client state and caches...");
    CLIENT.lock().unwrap().take();
    SYNC_SERVICE.lock().unwrap().take();
    TOMBSTONED_ROOMS.lock().unwrap().clear();
    IGNORED_USERS.lock().unwrap().clear();
    DEFAULT_SSO_CLIENT.lock().unwrap().take();
    // Note: Taking REQUEST_SENDER closes the channel sender, causing the async_worker task to exit its loop
    // This triggers the "async_worker task ended unexpectedly" error in the monitor task, but this is expected during logout
    REQUEST_SENDER.lock().unwrap().take();
    log!("Client state and caches cleared after successful server logout.");

    // Desktop UI has tabs that must be properly closed, while mobile UI has no tabs concept.
    if is_desktop {
        log!("Requesting to close all tabs in desktop");
        let (tx, rx)  = oneshot::channel::<bool>();
        Cx::post_action(MainDesktopUiAction::CloseAllTabs { on_close_all: tx });
        match rx.await {
            Ok(_) => {
                log!("Received signal that the MainDesktopUI successfully closed all tabs");
            },
            Err(e)=> {
                let error_msg = format!("Close all tab failed {e}");
                log!("Error :{}", error_msg);
                Cx::post_action(LogoutAction::LogoutFailure(error_msg.to_string()));
                return Err(anyhow::anyhow!(error_msg));
            },
        }
    }

    log!("Deleting latest user ID file...");
    // We delete latest_user_id here for the following reasons:
    // 1. we delete the latest user ID such that Robrix won't auto-login the next time it starts,
    // 2. we don't delete the session file, such that the user could re-login using that session in the future.
    if let Err(e) = delete_latest_user_id().await {
        errors.push(e.to_string());
    }

    shutdown_background_tasks().await;
    // Restart the Matrix tokio runtime
    // This is a critical step; failure might prevent future logins
    log!("Restarting Matrix tokio runtime...");
    if start_matrix_tokio().is_err() {
        // Send failure notification and return immediately, as the runtime is fundamental
        let final_error_msg = String::from("Logout succeeded, but Robrix could not re-connect to the Matrix backend. Please exit and restart Robrix");
        Cx::post_action(LogoutAction::LogoutFailure(final_error_msg.clone()));
        return Err(anyhow::anyhow!(final_error_msg));
    }
    log!("Matrix tokio runtime restarted successfully.");

    // --- Final result handling ---
    if errors.is_empty() {
        // Complete success
        log!("Logout process completed successfully.");
        Cx::post_action(LogoutAction::LogoutSuccess);
        Ok(())
    } else {
        // Partial success (server logout ok, but cleanup errors)
        let warning_msg = format!(
            "Logout completed, but some cleanup operations failed: {}",
            errors.join("; ")
        );
        log!("Warning: {}", warning_msg);
        Cx::post_action(LogoutAction::LogoutSuccess);
        Ok(())
    }
}

async fn shutdown_background_tasks() {
    let mut rt_guard = TOKIO_RUNTIME.lock().unwrap();
    if let Some(existing_rt) = rt_guard.take() {
        existing_rt.shutdown_background();
    }
}

```

The operations that triggered the panic were:

1. Desktop mode open multiple rooms.
2. Switch to mobile.
3. Logout in mobile.
4. Enlarge the window large enough for desktop.
5. Login again.
6. (panic)

At that time, two issues were identified:

- The memory state left by desktop was not properly handled during the logout process in mobile mode
- According to the initial report, we can see that the program's backtrace showed: thread 'main' panicked at /Users/alanpoon/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/deadpool-runtime-0.1.4/src/lib.rs:101:22: there is no reactor running, must be called from the context of a Tokio 1.x runtime
The matrix-sdk version at that time was 9676daee5ab864088993f869de52ec5d8b72cce9
Question 1 is not very relevant to the current analysis, as the handling omission was fixed in subsequent versions. We'll mainly discuss issue 2.

### The core issues are as follows:

```rust
1. The most "dangerous" operation in the entire process is closing the tokio-runtime and then restarting a brand new runtime
2. The panic message appears in deadpool-runtime-0.1.4

```

Using cargo.lock for analysis, we get a dependency chain: matrix-sdk -> matrix-sdk-sqlite -> rusqlite -> deadpool-sqlite -> deadpool-runtime
Since it's a tokio-related issue, **we use tokio-console to analyze the problem**
Note: Frame 77 in [https://github.com/project-robius/robrix/pull/432#discussion\\_r2171202111](https://github.com/project-robius/robrix/pull/432#discussion%5C%5C_r2171202111) is related to the room\_member\_manager in the version at that time. (Alex later updated the code to remove room\_member\_manager, so this issue no longer exists in subsequent versions)
I added a relatively long sleep after shutdown\_background and before restart, observing the asynchronous tasks in tokio-console. I found that after calling shutdown\_background, there were still many deadpool-related asynchronous tasks existing.

This is consistent with the tokio documentation, as shutdown\_background will close the tokio-runtime but won't wait for the asynchronous tasks within it to finish. So we conclude that **this panic occurs because we closed the tokio-runtime but the asynchronous tasks within it still exist, and when there's no runtime, the asynchronous tasks still try to execute, causing the panic.**

So our problematic code is:

```rust
CLIENT.lock().unwrap().take();
.....
shutdown_background_tasks().await

```

When we CLIENT.lock().unwrap().take();, the matrix client starts to destruct, but before shutdown\_background\_tasks, there's no guarantee that all asynchronous tasks in the client have been fully processed, leading to panic.

Since the issue occurs in matrix-sdk, I read the matrix API trying to find corresponding cleanup logic to reclaim deadpool-runtime in advance, as the crash happens in deadpool-runtime. Unfortunately, matrix doesn't proactively provide an API to reclaim deadpool-runtime.

### Design of the Logout State Machine

Note: Strictly speaking, the design of the state machine is not directly related to the crash, but the handling of this crash issue benefits from the design of the logout state machine.

```rust
//! The logout process is complex and error-prone due to:
//! - Network operations that can fail or timeout
//! - Resource cleanup that must happen in specific order
//! - UI synchronization across desktop tabs
//! - Matrix SDK objects that can panic during destruction
//! - Need for progress feedback and cancellation support
//!
//! ## State Flow
//!
//!
//! Idle (0%) → PreChecking (10%) → StoppingSyncService (20%) → LoggingOutFromServer (30%)
//!     ↓                                                                    ↓
//!   Failed ←─────────────────────────────────────────────────────── PointOfNoReturn (50%) ⚠️
//!                                                                           ↓
//!                                                                   ClosingTabs (60%) [Desktop Only]
//!                                                                           ↓
//!                                                                   CleaningAppState (70%)
//!                                                                           ↓
//!                                                                   ShuttingDownTasks (80%)
//!                                                                           ↓
//!                                                                   RestartingRuntime (90%)
//!                                                                           ↓
//!                                                                     Completed (100%)
//!                                                                           ↓
//!                                                                        Failed
//! ```
//!
//! ## Critical Design Points

```

The code above illustrates the state transition diagram of the state machine.

Now the core logout code is as follows:

```rust
/// Execute the logout process
    pub async fn execute(&self) -> Result<()> {
        log!("LogoutStateMachine::execute() started");
        
        // Set logout in progress flag
        LOGOUT_IN_PROGRESS.store(true, Ordering::Relaxed);
        
        // Reset global point of no return flag
        LOGOUT_POINT_OF_NO_RETURN.store(false, Ordering::Relaxed);
        
        // Start from Idle state
        self.transition_to(
            LogoutState::PreChecking,
            "Checking prerequisites...".to_string(),
            10
        ).await?;
        
        // Pre-checks
        if let Err(e) = self.perform_prechecks().await {
            self.transition_to(
                LogoutState::Failed(e.clone()),
                format!("Precheck failed: {}", e),
                0
            ).await?;
            self.handle_error(&e).await;
            return Err(anyhow!(e));
        }
        
        // Stop sync service
        self.transition_to(
            LogoutState::StoppingSyncService,
            "Stopping sync service...".to_string(),
            20
        ).await?;
        
        if let Err(e) = self.stop_sync_service().await {
            self.transition_to(
                LogoutState::Failed(e.clone()),
                format!("Failed to stop sync service: {}", e),
                0
            ).await?;
            self.handle_error(&e).await;
            return Err(anyhow!(e));
        }
        
        // Server logout
        self.transition_to(
            LogoutState::LoggingOutFromServer,
            "Logging out from server...".to_string(),
            30
        ).await?;
        
        match self.perform_server_logout().await {
            Ok(_) => {
                self.point_of_no_return.store(true, Ordering::Release);
                LOGOUT_POINT_OF_NO_RETURN.store(true, Ordering::Release);
                self.transition_to(
                    LogoutState::PointOfNoReturn,
                    "Point of no return reached".to_string(),
                    50
                ).await?;
                
                // We delete latest_user_id after reaching LOGOUT_POINT_OF_NO_RETURN:
                // 1. To prevent auto-login with invalid session on next start
                // 2. While keeping session file intact for potential future login
                if let Err(e) = delete_latest_user_id().await {
                    log!("Warning: Failed to delete latest user ID: {}", e);
                }
            }
            Err(e) => {
                // Check if it's an M_UNKNOWN_TOKEN error
                if matches!(&e, LogoutError::Recoverable(RecoverableError::ServerLogoutFailed(msg)) if msg.contains("M_UNKNOWN_TOKEN")) {
                    log!("Token already invalidated, continuing with logout");
                    self.point_of_no_return.store(true, Ordering::Release);
                    LOGOUT_POINT_OF_NO_RETURN.store(true, Ordering::Release);
                    self.transition_to(
                        LogoutState::PointOfNoReturn,
                        "Token already invalidated".to_string(),
                        50
                    ).await?;
                    
                    // Same delete operation as in the success case above
                    if let Err(e) = delete_latest_user_id().await {
                        log!("Warning: Failed to delete latest user ID: {}", e);
                    }
                } else {
                    // Restart sync service since we haven't reached point of no return
                    if let Some(sync_service) = get_sync_service() {
                        sync_service.start().await;
                    }
                    
                    self.transition_to(
                        LogoutState::Failed(e.clone()),
                        format!("Server logout failed: {}", e),
                        0
                    ).await?;
                    self.handle_error(&e).await;
                    return Err(anyhow!(e));
                }
            }
        }
        
        // From here on, all failures are unrecoverable
        
        // Close tabs (desktop only)
        if self.config.is_desktop {
            self.transition_to(
                LogoutState::ClosingTabs,
                "Closing all tabs...".to_string(),
                60
            ).await?;
            
            if let Err(e) = self.close_all_tabs().await {
                let error = LogoutError::Unrecoverable(UnrecoverableError::PostPointOfNoReturnFailure(e.to_string()));
                self.transition_to(
                    LogoutState::Failed(error.clone()),
                    "Failed to close tabs".to_string(),
                    0
                ).await?;
                self.handle_error(&error).await;
                return Err(anyhow!(error));
            }
        }
        
        // Clean app state
        self.transition_to(
            LogoutState::CleaningAppState,
            "Cleaning up application state...".to_string(),
            70
        ).await?;
        
        // All static resources (CLIENT, SYNC_SERVICE, etc.) are defined in the sliding_sync module,
        // so the state machine delegates the cleanup operation to sliding_sync's clean_app_state function
        // rather than accessing these static variables directly from outside the module.
        if let Err(e) = clean_app_state(&self.config).await {
            let error = LogoutError::Unrecoverable(UnrecoverableError::PostPointOfNoReturnFailure(e.to_string()));
            self.transition_to(
                LogoutState::Failed(error.clone()),
                "Failed to clean app state".to_string(),
                0
            ).await?;
            self.handle_error(&error).await;
            return Err(anyhow!(error));
        }
        
        // Shutdown tasks
        self.transition_to(
            LogoutState::ShuttingDownTasks,
            "Shutting down background tasks...".to_string(),
            80
        ).await?;
        
        self.shutdown_background_tasks().await;
        
        // Restart runtime
        self.transition_to(
            LogoutState::RestartingRuntime,
            "Restarting Matrix runtime...".to_string(),
            90
        ).await?;
        
        if let Err(e) = self.restart_runtime().await {
            let error = LogoutError::Unrecoverable(UnrecoverableError::RuntimeRestartFailed);
            self.transition_to(
                LogoutState::Failed(error.clone()),
                format!("Failed to restart runtime: {}", e),
                0
            ).await?;
            self.handle_error(&error).await;
            return Err(anyhow!(error));
        }
        
        // Success!
        self.transition_to(
            LogoutState::Completed,
            "Logout completed successfully".to_string(),
            100
        ).await?;

        // CloseSetting after logout
        Cx::post_action(SettingsAction::CloseSettings);

        // Reset logout in progress flag
        LOGOUT_IN_PROGRESS.store(false, Ordering::Relaxed);
        Cx::post_action(LogoutAction::LogoutSuccess);
        Ok(())
    }
```

Additionally, here's the supplementary code:

```rust
pub async fn clean_app_state(config: &LogoutConfig) -> Result<()> {
    // Clear resources normally, allowing them to be properly dropped
    // This prevents memory leaks when users logout and login again without closing the app
    CLIENT.lock().unwrap().take();
    log!("Client cleared during logout");

    SYNC_SERVICE.lock().unwrap().take();
    log!("Sync service cleared during logout");

    REQUEST_SENDER.lock().unwrap().take();
    log!("Request sender cleared during logout");

    // Only clear collections that don't contain Matrix SDK objects
    TOMBSTONED_ROOMS.lock().unwrap().clear();
    IGNORED_USERS.lock().unwrap().clear();
    ALL_JOINED_ROOMS.lock().unwrap().clear();

    let (tx, rx) = oneshot::channel::<bool>();
    Cx::post_action(LogoutAction::CleanAppState { on_clean_appstate: tx });

    match tokio::time::timeout(config.app_state_cleanup_timeout, rx).await {
        Ok(Ok(_)) => {
            log!("Received signal that app state was cleaned successfully");
            Ok(())
        }
        Ok(Err(e)) => Err(anyhow!("Failed to clean app state: {}", e)),
        Err(_) => Err(anyhow!("Timed out waiting for app state cleanup")),
    }
}

```

Now, the reclamation of tokio asynchronous tasks, especially regarding deadpool-runtime in matrix, is handled between clean_app_state and shutdown_background_tasks. In the new state machine, we have more operations between CLIENT.lock().unwrap().take(); (start destructing asynchronous tasks in matrix) and shutdown_background_tasks, giving the program more time for destruction. **Note: We still don't have an API to actively handle deadpool-runtime in matrix.**

Now, there are no more panics related to deadpool in the code.

As a comparison:

```rust
pub async fn clean_app_state(config: &LogoutConfig) -> Result<()> {
    // Clear resources normally, allowing them to be properly dropped
    // This prevents memory leaks when users logout and login again without closing the app
    CLIENT.lock().unwrap().take();
    log!("Client cleared during logout");

    SYNC_SERVICE.lock().unwrap().take();
    log!("Sync service cleared during logout");

    REQUEST_SENDER.lock().unwrap().take();
    log!("Request sender cleared during logout");

    // Only clear collections that don't contain Matrix SDK objects
    TOMBSTONED_ROOMS.lock().unwrap().clear();
    IGNORED_USERS.lock().unwrap().clear();
    ALL_JOINED_ROOMS.lock().unwrap().clear();

    // let (tx, rx) = oneshot::channel::<bool>();
    // Cx::post_action(LogoutAction::CleanAppState { on_clean_appstate: tx });

    // match tokio::time::timeout(config.app_state_cleanup_timeout, rx).await {
    //     Ok(Ok(_)) => {
    //         log!("Received signal that app state was cleaned successfully");
    //         Ok(())
    //     }
    //     Ok(Err(e)) => Err(anyhow!("Failed to clean app state: {}", e)),
    //     Err(_) => Err(anyhow!("Timed out waiting for app state cleanup")),
    // }

    Ok(())
}

```

If we comment out the code as shown above, canceling this time-consuming operation, and then logout, we can still see panics related to deadpool-runtime.

### About Shutdown and Leak

The above is an analysis of logout. As an exit function, I feel obligated to address issues in shutdown (closing the process).

Through the above analysis, I have reached the conclusion:

> The deadpool-runtime panic that occurs during the exit process is due to not fully ending asynchronous tasks before closing the runtime. Or, it's entirely an issue of destruction order.
>

In the logout state machine, because we adjusted the order of the state machine, we gave more time for the client to destruct when it's being destructed, avoiding the deadpool-runtime panic. However, we don't have a state machine to perform such a series of operations during shutdown, and we don't have an API to pre-release deadpool-runtime in the matrix client. So if we directly shutdown robrix, this crash information will point to the robrix program.

Therefore, I believe that since we have no way to release asynchronous tasks in the program, we might as well directly forget them, especially forgetting the tokio-runtime. Since the program is about to shutdown, forgetting might be acceptable.

This design is the core idea of using leak in shutdown.

### Current Situation

The current situation is a bit interesting. In the current version, I tried:

```rust
fn cleanup_before_shutdown(&mut self) {

    log!("Starting shutdown cleanup...");

    // Clear user profile cache first to prevent thread-local destructor issues
    // This must be done before leaking the tokio runtime
    clear_all_caches();
    log!("Cleared user profile cache");

    // Set logout in progress to suppress error messages
    LOGOUT_IN_PROGRESS.store(true, Ordering::Relaxed);

    // Immediately take and leak all resources to prevent any destructors from running
    // This is a controlled leak at shutdown to avoid the deadpool panic

    // Take the runtime first and leak it
    leak_runtime();

    // Take and leak the client
    leak_client();

    // Take and leak the sync service
    leak_sync_service();

    // Take and leak the request sender
    leak_request_sender();

    // Don't clear any collections or caches as they might contain references
    // to Matrix SDK objects that would trigger the deadpool panic
    log!("Shutdown cleanup completed - all resources leaked to prevent panics");
}

```

This code is in src/app.rs. I now try not to call this method, which means not actively leaking these resources during shutdown, and the program still doesn't crash. (Note that I did encounter crash errors in previous versions)

Here are some possible analyses:

Change in execution order:

Previous issue:
shutdown → clear_all_caches() → Matrix SDK objects in cache destruct → access potentially closed runtime → crash

Current safe process:
logout → clean_app_state() → Matrix SDK core resources already cleared → clear_all_caches() → safe
shutdown → do nothing → operating system reclaims resources → safe

1. Key contribution of the state machine
2. Separated the handling logic of logout and shutdown
3. Ensured correct cleanup order (clear dependencies first, then clear dependents)
4. Provided clear timing guarantees (perform dangerous operations only when it's safe)

Leaking is indeed a dangerous operation. Of course, the current situation suggests that the previous code might have been over-protective, and we might consider removing the related code.
