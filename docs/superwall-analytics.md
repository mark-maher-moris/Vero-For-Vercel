# Superwall Analytics Implementation

This document describes the comprehensive analytics tracking implementation using Superwall in the Vero app.

## Overview

The app now uses Superwall as both a paywall solution and an analytics database to track user flows, feature engagement, and conversion events.

## User Attributes (Segmentation)

User attributes are set when a user logs in at `@/Users/markmaher/Desktop/MAC/vercel-app/lib/providers/app_state.dart:119-133`:

| Attribute | Description |
|-----------|-------------|
| `user_id` | Unique identifier from Vercel API |
| `username` | Vercel username |
| `email` | User email address |
| `plan` | Current plan (free/pro) |
| `project_count` | Number of projects the user has |
| `team_count` | Number of teams the user belongs to |
| `has_pro` | Boolean indicating if user has Pro subscription |

## Tracked Events

### Screen Views

| Screen | Event Name | Properties |
|--------|------------|------------|
| Onboarding | `screen_view` | `total_pages`, `current_page` |
| Login | `screen_view` | - |
| Dashboard | `screen_view` | `project_count`, `has_teams` |
| Project Workspace | `screen_view` | `project_id`, `project_name`, `framework` |
| Subscription | `screen_view` | `is_pro`, `has_error` |

### User Actions

| Action | Event Name | Context | Properties |
|--------|------------|---------|------------|
| Login attempt | `user_action` | `login` | - |
| Login success | `user_action` | `app_state` | - |
| Logout | `user_action` | `app_state` | - |
| Import GitHub project | `user_action` | `dashboard` | - |
| Switch team | `user_action` | `dashboard` | - |
| View project | `project_action` | - | `project_id`, `project_name` |
| Switch tab | `user_action` | `project_workspace` | `tab_name`, `project_id` |
| Tab tapped | `user_action` | `project_workspace` | `tab_name`, `is_pro_tab`, `is_pro_user` |
| Onboarding page view | `user_action` | `onboarding` | `page_index`, `page_name`, `total_pages` |
| Onboarding complete | `user_action` | `onboarding` | `total_pages_viewed` |

### Feature Usage

| Feature | Event Name | Properties |
|---------|------------|------------|
| Redeploy | `deployment_action` | `action: redeploy`, `project_id`, `project_name` |
| Pro tab access attempt | `subscription_paywall_triggered` | `trigger: pro_tab_access`, `tab_name` |

### Subscription Events

| Event | Event Name | Properties |
|-------|------------|------------|
| Paywall triggered | `subscription_paywall_triggered` | `trigger`, `tab_name` |
| Paywall opened | `subscription_paywall_opened` | `context` |
| Purchase complete | `subscription_purchase_complete` | `context` |
| Restore started | `subscription_restore_started` | `context` |
| Restore complete (found) | `subscription_restore_complete` | `context`, `found_subscription: true` |
| Restore complete (not found) | `subscription_restore_complete` | `context`, `found_subscription: false` |

### Error Events

| Error | Event Name | Properties |
|-------|------------|------------|
| Login failed | `error` | `error_type: login_failed`, `error_message` |

### Placements Registered

These placements can trigger paywalls in the Superwall dashboard:

| Placement | Trigger Location |
|-----------|-----------------|
| `after_onboarding` | `@/Users/markmaher/Desktop/MAC/vercel-app/lib/screens/onboarding_screen.dart:130` |
| `projects_screen` | `@/Users/markmaher/Desktop/MAC/vercel-app/lib/screens/dashboard_screen.dart:33` |
| `custom_event` | Used for all analytics events via `@/Users/markmaher/Desktop/MAC/vercel-app/lib/services/superwall_service.dart:193` |
| `manual_paywall` | Used when calling `presentPaywall()` |

## User Flow Tracking

The following user flows are tracked:

1. **Onboarding Flow**
   - Screen views for each slide (privacy, opensource, github_support)
   - Onboarding completion event with pages viewed count
   - Paywall trigger after onboarding

2. **Authentication Flow**
   - Login screen view
   - Login attempt
   - Login success/failure
   - User identification with Superwall
   - User attributes set for segmentation

3. **Project Management Flow**
   - Dashboard view with project count
   - Project card taps with project details
   - Project workspace view with framework info
   - Tab switching with project context
   - Pro tab access attempts (paywall triggers)

4. **Subscription Flow**
   - Paywall opens
   - Subscription purchases
   - Purchase restores
   - Subscription status changes (via delegate)

5. **Feature Engagement**
   - Redeploy actions
   - Team switching
   - GitHub project imports

## Superwall Delegate Events

The `@/Users/markmaher/Desktop/MAC/vercel-app/lib/services/superwall_service.dart:182-355` delegate receives all Superwall events:

- `handleSuperwallEvent` - All paywall events
- `willPresentPaywall` / `didPresentPaywall` - Paywall presentation
- `willDismissPaywall` / `didDismissPaywall` - Paywall dismissal
- `subscriptionStatusDidChange` - Subscription status changes
- `handleCustomPaywallAction` - Custom paywall actions

## Dashboard Analytics

In your Superwall dashboard, you can now analyze:

1. **Funnel Analysis**
   - Onboarding completion rate
   - Paywall conversion rates
   - Free → Pro conversion

2. **User Segmentation**
   - Compare behavior by `plan` attribute
   - Analyze by `project_count` buckets
   - Segment by `team_count`

3. **Feature Adoption**
   - Track which Pro features are accessed most
   - Identify drop-off points in the user journey

4. **Retention**
   - Track returning users by `user_id`
   - Monitor re-engagement with team switches

## Implementation Files

Key files implementing analytics:

- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/services/superwall_service.dart` - Analytics service methods
- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/providers/app_state.dart` - User identification and attributes
- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/screens/onboarding_screen.dart` - Onboarding flow tracking
- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/screens/login_screen.dart` - Authentication tracking
- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/screens/dashboard_screen.dart` - Dashboard actions
- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/screens/project_workspace_screen.dart` - Project engagement
- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/screens/subscription_screen.dart` - Subscription events
- `@/Users/markmaher/Desktop/MAC/vercel-app/lib/widgets/project_card.dart` - Project interaction callbacks

## Next Steps for Dashboard Configuration

1. Log into your Superwall dashboard: https://superwall.com/applications
2. Create placements matching the ones listed above
3. Set up paywall campaigns for each placement
4. Configure analytics dashboards using the event names
5. Create user segments based on the attributes
