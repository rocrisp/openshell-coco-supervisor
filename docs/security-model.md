# Security model and secret-path limitations

## What this PoC protects

This PoC runs the **OpenShell supervisor** inside a confidential Kata VM. The intended protection is:

- supervisor memory is protected by the TEE,
- supervisor runtime state is protected while in use,
- when the secret path is fully integrated, credentials are released only after successful hardware attestation,
- the agent sandbox cannot directly read the supervisor’s protected memory.

This is a meaningful improvement over running the supervisor in an ordinary Pod, because it protects the security-critical controller from memory snooping and tampering by a compromised host, hypervisor, or privileged infrastructure administrator.

## What this PoC does not automatically protect

A confidential supervisor does **not** make the entire OpenShell system confidential.

If a credential is stored or transported through an unprotected intermediary, an attacker does not need to compromise the supervisor’s protected memory. They can steal the credential upstream.

Examples of unprotected upstream paths include:

- an unencrypted Kubernetes Secret,
- a plaintext credential copied into the OpenShell gateway,
- a provider credential stored in the gateway database,
- a secret mounted into a non-confidential helper Pod,
- a credential passed through a component that is not attested.

In those cases, the attacker can bypass the protected supervisor entirely and take the key from the weaker upstream component.

## Required end-to-end credential path

For end-to-end confidentiality, the credential path should be:

```text
Trustee
  ↓
attestation evidence from the confidential supervisor VM
  ↓
Trustee verifies hardware and software measurements
  ↓
secret released directly to the attested supervisor
  ↓
supervisor injects the credential only into approved requests
```

The important property is that the secret must not pass through an untrusted or non-confidential intermediary in plaintext.

## Current PoC limitation

The current repository deploys a Helm umbrella chart containing:

- the OpenShift sandboxed containers Operator,
- the confidential Kata runtime,
- Trustee,
- OpenShell,
- a supervisor runtime-class patch.

However, the repository now creates a supervisor-specific `initdata` ConfigMap and configures Kyverno to inject it into the confidential supervisor Pod. That initdata configures the guest attestation agent and Confidential Data Hub to use Trustee.

That means this PoC currently demonstrates:

- confidential supervisor runtime placement,
- Kata confidential VM setup,
- Trustee deployment,
- Trustee URL and certificate delivery into the guest through initdata,
- Kyverno-based `cc_init_data` injection,

but it does **not** yet prove the complete end-to-end secret path.

`test/07-attested-secret-retrieval.yml` is the next validation step: it creates
a `kata-remote` workload, injects the supervisor initdata through Kyverno, and
waits for the workload to retrieve `default/kbsres1/key1` from Trustee.

## Required follow-up

To close the gap:

1. Store provider credentials directly in Trustee or another hardware-attested secret provider.
2. Configure the supervisor to retrieve credentials only after successful attestation.
3. Avoid delivering the real credential through an unencrypted Kubernetes Secret or the non-confidential gateway.
4. Verify that an unattested supervisor cannot retrieve the secret.
5. Verify that the agent sandbox still receives only placeholder credentials.
6. Log or audit secret-release decisions without exposing secret values.

## Security claim

The precise claim for the current PoC is:

> The OpenShell supervisor can run inside a confidential Kata VM, protecting its in-use memory and runtime state from a compromised host.

The stronger end-to-end claim requires:

> Credentials are stored only in Trustee, released directly to the attested confidential supervisor, and never exposed in plaintext to the gateway, Kubernetes Secrets, or the agent sandbox.

The current repository is working toward the second claim, but the direct Trustee-to-supervisor credential integration is still an implementation gap.
