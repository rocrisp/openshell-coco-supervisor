# Kata Containers and confidential containers

## Short answer

Yes. **Kata Containers is part of the confidential containers stack**, but it is not the whole stack by itself.

## Relationship

```text
Confidential Containers
  └── Kata Containers
        └── lightweight VM
              └── guest kernel
                    └── your container
```

More completely:

```text
OpenShift sandboxed containers
  └── Kata Containers
        └── confidential VM
              └── TEE hardware protection
                    └── workload

Trustee
  └── attestation
  └── policy-gated secret release
```

## What Kata contributes

Kata Containers provides the VM boundary.

A normal container usually shares the host kernel:

```text
host kernel
  └── container
```

Kata runs the container inside a lightweight VM:

```text
host
  └── VM
      └── guest kernel
          └── container
```

That gives:

- a separate guest kernel,
- stronger isolation from the host,
- a place where a TEE can protect workload memory,
- support for confidential VMs on Intel TDX, AMD SEV-SNP, or similar hardware.

## What makes it confidential

Kata alone provides stronger isolation, but it does not automatically provide confidentiality.

Confidential containers require the combination of:

1. **Kata Containers** — VM isolation
2. **TEE hardware** — Intel TDX, AMD SEV-SNP, IBM Secure Execution, or another supported trusted execution environment
3. **Attestation** — prove that the workload is running on trusted hardware
4. **Trustee** — release secrets only after successful attestation
5. **Encrypted memory and protected state** — protect data while it is in use

The accurate statement is:

> Kata Containers is the runtime foundation that lets a container run inside a VM. Confidential containers use that Kata VM as a hardware-protected, attested environment.

## Runtime classes

| RuntimeClass | Meaning |
|---|---|
| `kata` | Pod runs in a lightweight VM |
| `kata-cc` | Pod runs in a local confidential VM on TEE hardware |
| `kata-remote` | Pod runs in a cloud-provisioned confidential VM, used with peer pods |

For the Azure / ARO path used by this repository, the relevant runtime is **`kata-remote`**.

## Summary

- **Kata** = VM-isolated container runtime
- **Confidential containers** = Kata VM + TEE hardware + attestation + Trustee secret release

Kata is the runtime foundation. Confidential containers add hardware protection, attestation, and policy-gated secret release on top of that foundation.
