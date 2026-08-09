Project Assistant Memory Architecture

Status: Architecture Contract
Version: 1.0
Last Updated: 2026-08-09
Owner: YachtCoreOS



1. Purpose

This document defines how Project Assistant stores, classifies, retrieves, protects, and acts upon information.

The architecture must preserve a clear distinction between:

● Verified facts

● User statements

● Interpretations

● Suggestions

● Predictions

● Simulations

● Professional decisions

● Experimental outcomes

AI-generated content must never silently become a verified fact, professional authorization, or final high-impact decision.



2. Core Principles

1. Human authority is preserved.

2. AI-generated information is decision support only.

3. Facts and interpretations are stored separately.

4. Sensitive information receives heightened protection.

5. Access is limited by role, purpose, and need to know.

6. High-impact actions require explicit human approval.

7. Medical or clinical decisions require an appropriately licensed professional.

8. Consent must be specific, informed, recorded, and revocable where applicable.

9. Experimental data must remain separate from verified production data.

10. Every consequential change must be auditable and recoverable.

11. Privacy and cybersecurity protections apply by design and by default.

12. The system must support correction, deletion, appeal, and incident reporting.



3. Memory Classes

3.1 Shared Memory

Project information authorized for access across approved users and devices.

Examples:

● Project status

● Approved decisions

● Published artifacts

● Assigned work

● Verified operational information

3.2 Device Memory

Information kept locally on an authorized device.

Examples:

● Interface preferences

● Draft content

● Offline action queue

● Temporary cached project records

Device memory must not weaken server-side permissions.

3.3 Session Memory

Temporary information required for the active session.

Examples:

● Current screen

● Unsaved form state

● Temporary assistant context

● Active filters

Session memory expires and must not become permanent without an authorized save.

3.4 Sensitive Memory

Information requiring heightened protection.

Examples:

● Medical conditions

● Allergies

● Medication information

● Disability information

● Names and addresses

● Contact information

● Identification documents

● Financial information

● Biometric or genetic information

● Race or ethnicity

● Religious beliefs

● Sexual orientation

● Gender identity

● Indigenous or tribal identity

● Immigration or citizenship information

Sensitive memory must use restricted access, encryption, purpose limitation, retention controls, and enhanced audit logging.

3.5 Professional Decision Memory

A decision made or authorized by a qualified human professional.

It must record:

● Professional role

● Required license or authorization

● Jurisdiction, when applicable

● Review date and time

● Evidence reviewed

● AI suggestion reviewed

● Final human decision

● Differences from the AI suggestion

● Reviewer confirmation

AI output must never populate this object as the final decision.

3.6 Experimental Memory

Information created in simulations, tests, prototypes, or sandbox environments.

Experimental information must:

● Be visibly labeled

● Remain isolated from verified production records

● Identify its assumptions

● Identify its baseline version

● Never trigger a real-world action without human approval



4. Required Objects

ProjectState

Represents the current verified state of a project.

Checkpoint

A recoverable saved position following a meaningful action or decision.

Event

An observed or reported occurrence.

Decision

An approved human decision and its supporting reasoning.

Artifact

A document, image, code file, video, report, dataset, or other project output.

ContextSnapshot

Relevant conditions surrounding an event, decision, or suggestion.

MemoryLink

A relationship between records without merging their meanings.

Experiment

A controlled sandbox variation.

Outcome

The observed result of a change, experiment, or decision.

BaselineVersion

The latest verified and recoverable stable state.

PermissionScope

Defines who may view, create, edit, approve, export, or delete information.

ConsentRecord

Records permission for a specific collection, use, disclosure, or research purpose.

SensitiveDataClassification

Identifies the sensitivity, purpose, jurisdiction, and required safeguards for data.

SafetyInterruption

Records when the system detected a high-risk subject and displayed a warning.

ProfessionalReview

Records independent review by an appropriately qualified human.

HumanDecision

Records the final decision and the person authorized to make it.

ResearchAuthorization

Records authorization for research or secondary use of information.

DataSubjectRequest

Tracks access, correction, deletion, portability, restriction, or consent withdrawal.

ConductReport

Records a reported violation of safety, privacy, nondiscrimination, or conduct rules.

Investigation

Tracks the authorized review of a report.

Appeal

Records a request for independent reconsideration.

SecurityIncident

Records suspected or confirmed compromise, loss, misuse, or unauthorized access.

BreachNotification

Tracks legally or contractually required notifications.

RetentionRule

Defines how long a category of information may be retained.

JurisdictionProfile

Identifies which geographic and industry requirements may apply.

AuditEvent

Creates a tamper-resistant record of consequential system and user activity.



5. Universal Record Fields

Every persistent record must support:

```text
id
project_id
organization_id
created_at
created_by
updated_at
updated_by
status
source_type
source_reference
confidence
visibility_scope
sensitivity_level
jurisdiction
purpose
retention_rule_id
version
is_ai_generated
requires_human_review
review_status
```

Predictions, simulations, and experiments must also support:

```text
evidence_level
assumptions
limitations
environment_snapshot_id
baseline_version_id
experiment_id
expires_at
```



6. Evidence Classification

Every important statement must be classified as one of the following:

Verified Fact

Supported by an authoritative source or verified observation.

User-Reported Information

Provided by a user but not independently verified.

Interpretation

A human or AI explanation of available information.

Suggestion

A proposed option that has not been approved.

Prediction

A possible future outcome based on stated evidence and assumptions.

Simulation

A calculated hypothetical scenario.

Professional Decision

A final decision made by an appropriately authorized human.

The system must never convert a suggestion, prediction, or simulation into a verified fact or professional decision.



7. High-Impact Decision Rule

High-impact subjects include:

● Medical or clinical matters

● Allergies and food safety

● Personal safety

● Navigation

● Engineering and vessel systems

● Legal or regulatory decisions

● Employment decisions

● Financial commitments

● Environmental hazards

● Emergency response

For high-impact subjects, the system must:

1. Identify the risk category.

2. Display the applicable warning.

3. Explain known limitations.

4. Preserve supporting sources.

5. Require an authorized human review.

6. Prevent automatic execution.

7. Record the final human decision.

8. Preserve an audit trail.



8. Medical and Health Safety Boundary

Project Assistant is not a healthcare provider.

The system and company:

● Do not hold a medical license

● Do not diagnose medical conditions

● Do not prescribe medication or treatment

● Do not authorize clinical action

● Do not determine medical fitness for duty

● Do not replace a physician or other licensed medical professional

● Do not represent AI output as medical approval

Best-practice safeguards may reduce risk but cannot guarantee that AI-generated information is complete, accurate, current, or appropriate for a specific person.

Only an appropriately licensed medical professional may make or authorize a clinical decision within the scope of that professional’s license.

The system must not imply that a disclaimer eliminates every possible legal responsibility of the company, its operators, or its technology providers. Contractual limitations of liability must be addressed separately in attorney-reviewed Terms of Use.



9. Medical Safety Interruption

The following subjects trigger an explicit safety interruption:

● Symptoms

● Injuries

● Medical conditions

● Medication

● Dosage

● Contraindications

● Allergies

● Pregnancy

● Mental health

● Substance use

● Disability

● Infectious disease

● Medical fitness for duty

● Diagnosis or treatment

Initial Warning

> **Health or medical information detected**
>
> This system is not a licensed medical provider and is not authorized to diagnose, prescribe, approve treatment, determine medical fitness, or make another clinical decision.
>
> Although safety controls and recognized best practices may be applied, AI-generated information can be incomplete, inaccurate, outdated, or inappropriate.
>
> A licensed medical professional must independently evaluate the situation and make any authorized medical decision.
>
> Do not enter another person’s medical information unless you are authorized to do so and have an appropriate lawful purpose.

Available actions:

● Continue with authorized information

● Continue using de-identified information

● Contact a licensed medical professional

● Cancel

Consequential-Action Warning

> **Licensed professional authorization required**
>
> No medical or clinical action may be treated as authorized based on this AI output.
>
> Before proceeding, an appropriately licensed medical professional must review the relevant facts, independently assess the situation, and record the final decision.
>
> If there may be an emergency, contact local emergency services immediately.

Secure Response Requirements

The system must record:

```text
warning_type
warning_version
displayed_at
trigger_category
user_response
consent_record_id
professional_review_required
professional_review_id
final_human_decision_id
```

The system must never record clicking Continue as medical consent, professional review, or clinical authorization.



10. Privacy and Research Rules

Personal or sensitive information must not be used for research, model training, publication, product improvement, or an unrelated secondary purpose without the required authorization and legal basis.

Where consent is required, it must be:

● Explicit

● Specific

● Informed

● Freely given

● Recorded

● Versioned

● Withdrawable where applicable

● Separate from unrelated service acceptance

Research records must define:

```text
research_purpose
data_categories
legal_basis
consent_required
consent_record_id
de_identification_method
re_identification_risk
approved_recipients
retention_period
ethics_review_reference
withdrawal_process
```

Names, addresses, health conditions, and other direct identifiers must not be included when the purpose can be achieved with de-identified or minimized data.



11. Nondiscrimination and Human Rights

The system must not discriminate, retaliate, harass, exclude, or provide unequal service based on protected or sensitive characteristics.

Protected policy categories include:

● Race

● Color

● Ethnicity

● Ancestry

● National origin

● Indigenous or tribal identity

● Religion or belief

● Sex

● Pregnancy

● Gender

● Gender identity or expression

● Sexual orientation

● Age

● Disability

● Medical condition

● Genetic information

● Citizenship or immigration status

● Veteran status

● Language

● Culture

● Any additional status protected by applicable law

The system must not unnecessarily infer these characteristics.

High-impact outputs must be tested and reviewed for discriminatory effects.



12. Reporting and Enforcement

Users must be able to report:

● Safety concerns

● Medical-safety concerns

● Privacy violations

● Security vulnerabilities

● Harassment

● Discrimination

● Retaliation

● Unauthorized disclosure

● Misuse of AI

● Other prohibited conduct

Reports must support confidential handling and protection against retaliation.

Enforcement may include:

● Education

● Warning

● Feature restriction

● Temporary suspension

● Removal from a project

● Account termination

● Referral to appropriate authorities when required

Serious or repeated non-adherence may result in removal after appropriate review. Immediate restriction may occur when necessary to protect people, information, systems, or evidence.

An appeal path must be available where appropriate.



13. Questions, Concerns, and Communication Channels

The company must maintain separate communication channels for:

|Issue                               |Required channel                          |Handling priority        |
|------------------------------------|------------------------------------------|-------------------------|
|Immediate physical or medical danger|Local emergency services                  |Immediate                |
|Medical-safety concern              |Dedicated safety contact                  |Urgent triage            |
|Suspected privacy breach            |Privacy contact and urgent reporting form |Immediate triage         |
|Security vulnerability              |Security contact and secure reporting form|Acknowledge promptly     |
|Harassment or discrimination        |Confidential conduct-reporting channel    |Priority review          |
|Data access, correction, or deletion|Privacy request portal or contact         |Applicable legal deadline|
|Product support                     |Customer-support channel                  |Published service level  |
|Appeal                              |Independent appeals channel               |Published review timeline|

Before public release, every channel must display:

● A real monitored email address or form

● A real staffed telephone number when appropriate

● Operating hours and time zone

● Available languages and accessibility options

● Expected response time

● Emergency limitations

● What information will be collected

● Why that information is needed

● How the report will be protected and retained

Placeholder contact details must never be presented to users as operational channels.



14. Cybersecurity Requirements

The security program must follow recognized and current cybersecurity practices, including:

● Encryption in transit and at rest

● Multi-factor authentication and passkey support where practical

● Least-privilege access

● Role-based and purpose-based permissions

● Row-level security

● Secret management and key rotation

● Tamper-resistant audit logs

● Secure backups and restoration testing

● Vulnerability and dependency scanning

● Secure development and release review

● Incident detection and response

● Vendor risk assessment

● Data-processing agreements

● Breach-notification workflows

● Prompt-injection protection

● Sensitive-information output controls

● Protection against excessive AI agency

● Human approval before consequential AI actions

Security controls must be reviewed and updated as risks and standards change.



15. Reserved Future Integration: Serena

Serena is a future, separate safety project intended for yachting and hospitality point-of-sale environments.

Its anticipated purpose is to identify and interrupt food orders that may conflict with recorded allergy or dietary-safety information before the order reaches the kitchen.

Serena is not part of the current Project Assistant implementation.

Before integration, Serena will require a dedicated architecture addressing:

● Allergy-data authorization

● Identity and guest matching

● Ingredient-source verification

● Cross-contact and ingredient uncertainty

● Kitchen confirmation workflows

● Emergency escalation

● Point-of-sale integration security

● Human acknowledgment

● Licensed medical boundaries

● False-positive and false-negative risks

● Incident preservation

● Restaurant, vessel, and jurisdiction-specific requirements

Serena must never represent that an order is medically safe.

Its output must use language such as:

> **Potential allergy conflict detected.** Stop and verify the guest, ingredients, preparation method, and cross-contact risk with authorized personnel.

A human food-safety decision and the appropriate emergency response remain required.

Serena data must remain logically separated from Project Assistant until a formal, reviewed integration is approved.



16. Initial Supabase Scope

The first implementation should create only:

```text
projects
checkpoints
events
decisions
artifacts
consent_records
safety_interruptions
professional_reviews
human_decisions
audit_events
```

Later phases may add:

```text
sensitive_data_classifications
research_authorizations
conduct_reports
investigations
appeals
security_incidents
breach_notifications
retention_rules
jurisdiction_profiles
```



17. Release Gate

No health-sensitive or other high-impact feature may enter production until:

● Authentication works

● Permissions are tested

● Sensitive data is classified

● Consent is recorded

● Safety warnings are functional

● Professional-review gates are enforced

● Audit logging works

● Backups and restoration are tested

● Incident response is documented

● Privacy and security reviews are complete

● Public policies have received appropriate legal review



18. Final Architecture Rule

The assistant may organize, explain, compare, warn, and suggest.

It may not silently authorize, diagnose, prescribe, approve, or execute a high-impact decision reserved for a licensed, qualified, or legally authorized human.



19. Legal and Professional Review Notice

This document is a product architecture and governance specification. It is not legal advice, a privacy notice, a medical protocol, or a substitute for jurisdiction-specific review.

Before production release, qualified legal, privacy, cybersecurity, medical-safety, food-safety, and industry professionals must review the controls relevant to their respective fields.

  
