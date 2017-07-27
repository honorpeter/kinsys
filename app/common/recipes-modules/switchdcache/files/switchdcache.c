#include <linux/init.h>
#include <linux/kernel.h>
#include <linux/module.h>

#include <linux/ioport.h>
#include <asm/io.h>
#include <asm/cacheflush.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Takayuki Ujiie");
MODULE_DESCRIPTION("switchdcache: switch ARM's dcache mode");

typedef u32 UINTPTR;
typedef u32 INTPTR;

// extern s32  _stack_end;
// extern s32  __undef_stack;

////////////////////////////////////////////////////////////
// Constants
////////////////////////////////////////////////////////////
// {{{
/* The next two CP15 register accesses below have been deprecated in favor
 * of the new dsb and dmb instructions in Cortex A9.
 */
#define XREG_CP15_DATA_SYNC_BARRIER		"p15, 0, %0,  c7, c10, 4"
#define XREG_CP15_DATA_MEMORY_BARRIER		"p15, 0, %0,  c7, c10, 5"

#define XREG_CP15_CLEAN_DC_LINE_MVA_POU		"p15, 0, %0,  c7, c11, 1"

#define XREG_CP15_NOP2				"p15, 0, %0,  c7, c13, 1"

#define XREG_CP15_CLEAN_INVAL_DC_LINE_MVA_POC	"p15, 0, %0,  c7, c14, 1"
#define XREG_CP15_CLEAN_INVAL_DC_LINE_SW	"p15, 0, %0,  c7, c14, 2"

/* C8 Register Defines */
#define XREG_CP15_INVAL_TLB_IS			"p15, 0, %0,  c8,  c3, 0"
#define XREG_CP15_INVAL_TLB_MVA_IS		"p15, 0, %0,  c8,  c3, 1"
#define XREG_CP15_INVAL_TLB_ASID_IS		"p15, 0, %0,  c8,  c3, 2"
#define XREG_CP15_INVAL_TLB_MVA_ASID_IS		"p15, 0, %0,  c8,  c3, 3"

#define XREG_CP15_INVAL_ITLB_UNLOCKED		"p15, 0, %0,  c8,  c5, 0"
#define XREG_CP15_INVAL_ITLB_MVA		"p15, 0, %0,  c8,  c5, 1"
#define XREG_CP15_INVAL_ITLB_ASID		"p15, 0, %0,  c8,  c5, 2"

#define XREG_CP15_INVAL_DTLB_UNLOCKED		"p15, 0, %0,  c8,  c6, 0"
#define XREG_CP15_INVAL_DTLB_MVA		"p15, 0, %0,  c8,  c6, 1"
#define XREG_CP15_INVAL_DTLB_ASID		"p15, 0, %0,  c8,  c6, 2"

#define XREG_CP15_INVAL_UTLB_UNLOCKED		"p15, 0, %0,  c8,  c7, 0"
#define XREG_CP15_INVAL_UTLB_MVA		"p15, 0, %0,  c8,  c7, 1"
#define XREG_CP15_INVAL_UTLB_ASID		"p15, 0, %0,  c8,  c7, 2"
#define XREG_CP15_INVAL_UTLB_MVA_ASID		"p15, 0, %0,  c8,  c7, 3"

/* The CP15 register access below has been deprecated in favor of the new
 * isb instruction in Cortex A9.
 */
#define XREG_CP15_INST_SYNC_BARRIER		"p15, 0, %0,  c7,  c5, 4"
#define XREG_CP15_INVAL_BRANCH_ARRAY		"p15, 0, %0,  c7,  c5, 6"

#define XREG_CP15_INVAL_DC_LINE_MVA_POC		"p15, 0, %0,  c7,  c6, 1"
#define XREG_CP15_INVAL_DC_LINE_SW		"p15, 0, %0,  c7,  c6, 2"

#define XREG_CP15_VA_TO_PA_CURRENT_0		"p15, 0, %0,  c7,  c8, 0"
#define XREG_CP15_VA_TO_PA_CURRENT_1		"p15, 0, %0,  c7,  c8, 1"
#define XREG_CP15_VA_TO_PA_CURRENT_2		"p15, 0, %0,  c7,  c8, 2"
#define XREG_CP15_VA_TO_PA_CURRENT_3		"p15, 0, %0,  c7,  c8, 3"

#define XREG_CP15_VA_TO_PA_OTHER_0		"p15, 0, %0,  c7,  c8, 4"
#define XREG_CP15_VA_TO_PA_OTHER_1		"p15, 0, %0,  c7,  c8, 5"
#define XREG_CP15_VA_TO_PA_OTHER_2		"p15, 0, %0,  c7,  c8, 6"
#define XREG_CP15_VA_TO_PA_OTHER_3		"p15, 0, %0,  c7,  c8, 7"

#define XREG_CP15_CLEAN_DC_LINE_MVA_POC		"p15, 0, %0,  c7, c10, 1"
#define XREG_CP15_CLEAN_DC_LINE_SW		"p15, 0, %0,  c7, c10, 2"

/* C1 Register Defines */
#define XREG_CP15_SYS_CONTROL			"p15, 0, %0,  c1,  c0, 0"
#define XREG_CP15_AUX_CONTROL			"p15, 0, %0,  c1,  c0, 1"
#define XREG_CP15_CP_ACCESS_CONTROL		"p15, 0, %0,  c1,  c0, 2"

#define XREG_CP15_SECURE_CONFIG			"p15, 0, %0,  c1,  c1, 0"
#define XREG_CP15_SECURE_DEBUG_ENABLE		"p15, 0, %0,  c1,  c1, 1"
#define XREG_CP15_NS_ACCESS_CONTROL		"p15, 0, %0,  c1,  c1, 2"
#define XREG_CP15_VIRTUAL_CONTROL		"p15, 0, %0,  c1,  c1, 3"

/* XREG_CP15_CONTROL bit defines */
#define XREG_CP15_CONTROL_TE_BIT		0x40000000U
#define XREG_CP15_CONTROL_AFE_BIT		0x20000000U
#define XREG_CP15_CONTROL_TRE_BIT		0x10000000U
#define XREG_CP15_CONTROL_NMFI_BIT		0x08000000U
#define XREG_CP15_CONTROL_EE_BIT		0x02000000U
#define XREG_CP15_CONTROL_HA_BIT		0x00020000U
#define XREG_CP15_CONTROL_RR_BIT		0x00004000U
#define XREG_CP15_CONTROL_V_BIT			0x00002000U
#define XREG_CP15_CONTROL_I_BIT			0x00001000U
#define XREG_CP15_CONTROL_Z_BIT			0x00000800U
#define XREG_CP15_CONTROL_SW_BIT		0x00000400U
#define XREG_CP15_CONTROL_B_BIT			0x00000080U
#define XREG_CP15_CONTROL_C_BIT			0x00000004U
#define XREG_CP15_CONTROL_A_BIT			0x00000002U
#define XREG_CP15_CONTROL_M_BIT			0x00000001U

/* C0 Register defines */
#define XREG_CP15_MAIN_ID			"p15, 0, %0,  c0,  c0, 0"
#define XREG_CP15_CACHE_TYPE			"p15, 0, %0,  c0,  c0, 1"
#define XREG_CP15_TCM_TYPE			"p15, 0, %0,  c0,  c0, 2"
#define XREG_CP15_TLB_TYPE			"p15, 0, %0,  c0,  c0, 3"
#define XREG_CP15_MULTI_PROC_AFFINITY		"p15, 0, %0,  c0,  c0, 5"

#define XREG_CP15_PROC_FEATURE_0		"p15, 0, %0,  c0,  c1, 0"
#define XREG_CP15_PROC_FEATURE_1		"p15, 0, %0,  c0,  c1, 1"
#define XREG_CP15_DEBUG_FEATURE_0		"p15, 0, %0,  c0,  c1, 2"
#define XREG_CP15_MEMORY_FEATURE_0		"p15, 0, %0,  c0,  c1, 4"
#define XREG_CP15_MEMORY_FEATURE_1		"p15, 0, %0,  c0,  c1, 5"
#define XREG_CP15_MEMORY_FEATURE_2		"p15, 0, %0,  c0,  c1, 6"
#define XREG_CP15_MEMORY_FEATURE_3		"p15, 0, %0,  c0,  c1, 7"

#define XREG_CP15_INST_FEATURE_0		"p15, 0, %0,  c0,  c2, 0"
#define XREG_CP15_INST_FEATURE_1		"p15, 0, %0,  c0,  c2, 1"
#define XREG_CP15_INST_FEATURE_2		"p15, 0, %0,  c0,  c2, 2"
#define XREG_CP15_INST_FEATURE_3		"p15, 0, %0,  c0,  c2, 3"
#define XREG_CP15_INST_FEATURE_4		"p15, 0, %0,  c0,  c2, 4"

#define XREG_CP15_CACHE_SIZE_ID			"p15, 1, %0,  c0,  c0, 0"
#define XREG_CP15_CACHE_LEVEL_ID		"p15, 1, %0,  c0,  c0, 1"
#define XREG_CP15_AUXILARY_ID			"p15, 1, %0,  c0,  c0, 7"

#define XREG_CP15_CACHE_SIZE_SEL		"p15, 2, %0,  c0,  c0, 0"

/* C1 Register Defines */
#define XREG_CP15_SYS_CONTROL			"p15, 0, %0,  c1,  c0, 0"
#define XREG_CP15_AUX_CONTROL			"p15, 0, %0,  c1,  c0, 1"
#define XREG_CP15_CP_ACCESS_CONTROL		"p15, 0, %0,  c1,  c0, 2"

#define XREG_CP15_SECURE_CONFIG			"p15, 0, %0,  c1,  c1, 0"
#define XREG_CP15_SECURE_DEBUG_ENABLE		"p15, 0, %0,  c1,  c1, 1"
#define XREG_CP15_NS_ACCESS_CONTROL		"p15, 0, %0,  c1,  c1, 2"
#define XREG_CP15_VIRTUAL_CONTROL		"p15, 0, %0,  c1,  c1, 3"

#define XPS_L2CC_BASEADDR		0xF8F02000U

/* L2CC Register Offsets */
#define XPS_L2CC_ID_OFFSET		0x0000U
#define XPS_L2CC_TYPE_OFFSET		0x0004U
#define XPS_L2CC_CNTRL_OFFSET		0x0100U
#define XPS_L2CC_AUX_CNTRL_OFFSET	0x0104U
#define XPS_L2CC_TAG_RAM_CNTRL_OFFSET	0x0108U
#define XPS_L2CC_DATA_RAM_CNTRL_OFFSET	0x010CU

#define XPS_L2CC_EVNT_CNTRL_OFFSET	0x0200U
#define XPS_L2CC_EVNT_CNT1_CTRL_OFFSET	0x0204U
#define XPS_L2CC_EVNT_CNT0_CTRL_OFFSET	0x0208U
#define XPS_L2CC_EVNT_CNT1_VAL_OFFSET	0x020CU
#define XPS_L2CC_EVNT_CNT0_VAL_OFFSET	0x0210U

#define XPS_L2CC_IER_OFFSET		0x0214U		/* Interrupt Mask */
#define XPS_L2CC_IPR_OFFSET		0x0218U		/* Masked interrupt status */
#define XPS_L2CC_ISR_OFFSET		0x021CU		/* Raw Interrupt Status */
#define XPS_L2CC_IAR_OFFSET		0x0220U		/* Interrupt Clear */

#define XPS_L2CC_CACHE_SYNC_OFFSET		0x0730U		/* Cache Sync */
#define XPS_L2CC_DUMMY_CACHE_SYNC_OFFSET	0x0740U		/* Dummy Register for Cache Sync */
#define XPS_L2CC_CACHE_INVLD_PA_OFFSET		0x0770U		/* Cache Invalid by PA */
#define XPS_L2CC_CACHE_INVLD_WAY_OFFSET		0x077CU		/* Cache Invalid by Way */
#define XPS_L2CC_CACHE_CLEAN_PA_OFFSET		0x07B0U		/* Cache Clean by PA */
#define XPS_L2CC_CACHE_CLEAN_INDX_OFFSET	0x07B8U		/* Cache Clean by Index */
#define XPS_L2CC_CACHE_CLEAN_WAY_OFFSET		0x07BCU		/* Cache Clean by Way */
#define XPS_L2CC_CACHE_INV_CLN_PA_OFFSET	0x07F0U		/* Cache Invalidate and Clean by PA */
#define XPS_L2CC_CACHE_INV_CLN_INDX_OFFSET	0x07F8U		/* Cache Invalidate and Clean by Index */
#define XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET	0x07FCU		/* Cache Invalidate and Clean by Way */

#define XPS_L2CC_CACHE_DLCKDWN_0_WAY_OFFSET	0x0900U		/* Cache Data Lockdown 0 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_0_WAY_OFFSET	0x0904U		/* Cache Instruction Lockdown 0 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_1_WAY_OFFSET	0x0908U		/* Cache Data Lockdown 1 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_1_WAY_OFFSET	0x090CU		/* Cache Instruction Lockdown 1 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_2_WAY_OFFSET	0x0910U		/* Cache Data Lockdown 2 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_2_WAY_OFFSET	0x0914U		/* Cache Instruction Lockdown 2 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_3_WAY_OFFSET	0x0918U		/* Cache Data Lockdown 3 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_3_WAY_OFFSET	0x091CU		/* Cache Instruction Lockdown 3 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_4_WAY_OFFSET	0x0920U		/* Cache Data Lockdown 4 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_4_WAY_OFFSET	0x0924U		/* Cache Instruction Lockdown 4 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_5_WAY_OFFSET	0x0928U		/* Cache Data Lockdown 5 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_5_WAY_OFFSET	0x092CU		/* Cache Instruction Lockdown 5 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_6_WAY_OFFSET	0x0930U		/* Cache Data Lockdown 6 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_6_WAY_OFFSET	0x0934U		/* Cache Instruction Lockdown 6 by Way */
#define XPS_L2CC_CACHE_DLCKDWN_7_WAY_OFFSET	0x0938U		/* Cache Data Lockdown 7 by Way */
#define XPS_L2CC_CACHE_ILCKDWN_7_WAY_OFFSET	0x093CU		/* Cache Instruction Lockdown 7 by Way */

#define XPS_L2CC_CACHE_LCKDWN_LINE_ENABLE_OFFSET 0x0950U		/* Cache Lockdown Line Enable */
#define XPS_L2CC_CACHE_UUNLOCK_ALL_WAY_OFFSET	0x0954U		/* Cache Unlock All Lines by Way */

#define XPS_L2CC_ADDR_FILTER_START_OFFSET	0x0C00U		/* Start of address filtering */
#define XPS_L2CC_ADDR_FILTER_END_OFFSET		0x0C04U		/* Start of address filtering */

#define XPS_L2CC_DEBUG_CTRL_OFFSET		0x0F40U		/* Debug Control Register */

/* XPS_L2CC_CNTRL_OFFSET bit masks */
#define XPS_L2CC_ENABLE_MASK		0x00000001U	/* enables the L2CC */

/* XPS_L2CC_AUX_CNTRL_OFFSET bit masks */
#define XPS_L2CC_AUX_EBRESPE_MASK	0x40000000U	/* Early BRESP Enable */
#define XPS_L2CC_AUX_IPFE_MASK		0x20000000U	/* Instruction Prefetch Enable */
#define XPS_L2CC_AUX_DPFE_MASK		0x10000000U	/* Data Prefetch Enable */
#define XPS_L2CC_AUX_NSIC_MASK		0x08000000U	/* Non-secure interrupt access control */
#define XPS_L2CC_AUX_NSLE_MASK		0x04000000U	/* Non-secure lockdown enable */
#define XPS_L2CC_AUX_CRP_MASK		0x02000000U	/* Cache replacement policy */
#define XPS_L2CC_AUX_FWE_MASK		0x01800000U	/* Force write allocate */
#define XPS_L2CC_AUX_SAOE_MASK		0x00400000U	/* Shared attribute override enable */
#define XPS_L2CC_AUX_PE_MASK		0x00200000U	/* Parity enable */
#define XPS_L2CC_AUX_EMBE_MASK		0x00100000U	/* Event monitor bus enable */
#define XPS_L2CC_AUX_WAY_SIZE_MASK	0x000E0000U	/* Way-size */
#define XPS_L2CC_AUX_ASSOC_MASK		0x00010000U	/* Associativity */
#define XPS_L2CC_AUX_SAIE_MASK		0x00002000U	/* Shared attribute invalidate enable */
#define XPS_L2CC_AUX_EXCL_CACHE_MASK	0x00001000U	/* Exclusive cache configuration */
#define XPS_L2CC_AUX_SBDLE_MASK		0x00000800U	/* Store buffer device limitation Enable */
#define XPS_L2CC_AUX_HPSODRE_MASK	0x00000400U	/* High Priority for SO and Dev Reads Enable */
#define XPS_L2CC_AUX_FLZE_MASK		0x00000001U	/* Full line of zero enable */

#define XPS_L2CC_AUX_REG_DEFAULT_MASK	0x72360000U	/* Enable all prefetching, */
                                                        /* Cache replacement policy, Parity enable, */
                                                        /* Event monitor bus enable and Way Size (64 KB) */
#define XPS_L2CC_AUX_REG_ZERO_MASK	0xFFF1FFFFU	/* */

#define XPS_L2CC_TAG_RAM_DEFAULT_MASK	0x00000111U	/* latency for TAG RAM */
#define XPS_L2CC_DATA_RAM_DEFAULT_MASK	0x00000121U	/* latency for DATA RAM */

/* Interrupt bit masks */
#define XPS_L2CC_IXR_DECERR_MASK	0x00000100U	/* DECERR from L3 */
#define XPS_L2CC_IXR_SLVERR_MASK	0x00000080U	/* SLVERR from L3 */
#define XPS_L2CC_IXR_ERRRD_MASK		0x00000040U	/* Error on L2 data RAM (Read) */
#define XPS_L2CC_IXR_ERRRT_MASK		0x00000020U	/* Error on L2 tag RAM (Read) */
#define XPS_L2CC_IXR_ERRWD_MASK		0x00000010U	/* Error on L2 data RAM (Write) */
#define XPS_L2CC_IXR_ERRWT_MASK		0x00000008U	/* Error on L2 tag RAM (Write) */
#define XPS_L2CC_IXR_PARRD_MASK		0x00000004U	/* Parity Error on L2 data RAM (Read) */
#define XPS_L2CC_IXR_PARRT_MASK		0x00000002U	/* Parity Error on L2 tag RAM (Read) */
#define XPS_L2CC_IXR_ECNTR_MASK		0x00000001U	/* Event Counter1/0 Overflow Increment */

/* Address filtering mask and enable bit */
#define XPS_L2CC_ADDR_FILTER_VALID_MASK	0xFFF00000U	/* Address filtering valid bits*/
#define XPS_L2CC_ADDR_FILTER_ENABLE_MASK 0x00000001U	/* Address filtering enable bit*/

/* Debug control bits */
#define XPS_L2CC_DEBUG_SPIDEN_MASK	0x00000004U	/* Debug SPIDEN bit */
#define XPS_L2CC_DEBUG_DWB_MASK		0x00000002U	/* Debug DWB bit, forces write through */
#define XPS_L2CC_DEBUG_DCL_MASK		0x00000002U	/* Debug DCL bit, disables cache line fill */

#define IRQ_FIQ_MASK 0xC0U	/* Mask IRQ and FIQ interrupts in cpsr */

// }}}
////////////////////////////////////////////////////////////
// Asm
////////////////////////////////////////////////////////////
// {{{
/* Data Synchronization Barrier */
#define dsb()             \
  __asm__ __volatile__ (  \
    "dsb"                 \
    :                     \
    :                     \
    : "memory"            \
  )

#define mfcpsr() ({       \
  u32 rval = 0U;          \
  __asm__ __volatile__ (  \
    "mrs %0, cpsr\n"      \
    : "=r" (rval)         \
  );                      \
  rval;                   \
})

#define mtcpsr(v)         \
  __asm__ __volatile__ (  \
    "msr cpsr, %0\n"       \
    :                     \
    : "r" (v)             \
  )

/* CP15 operations */
#define mtcp(rn, v)       \
  __asm__ __volatile__ (  \
    "mcr " rn "\n"        \
    :                     \
    : "r" (v)             \
  );

#define mfcp(rn) ({       \
  u32 rval = 0U;          \
  __asm__ __volatile__ (  \
    "mrc " rn "\n"        \
    : "=r" (rval)         \
  );                      \
  rval;                   \
})

#define asm_cp15_clean_inval_dc_line_sw(param)  \
  __asm__ __volatile__ (                        \
    "mcr " XREG_CP15_CLEAN_INVAL_DC_LINE_SW     \
    :                                           \
    : "r" (param)                               \
  );

#define asm_cp15_clean_inval_dc_line_mva_poc(param) \
  __asm__ __volatile__ (                            \
    "mcr " XREG_CP15_CLEAN_INVAL_DC_LINE_MVA_POC    \
    :                                               \
    : "r" (param)                                   \
  );

#define asm_cp15_inval_dc_line_sw(param)  \
  __asm__ __volatile__ (                  \
    "mcr " XREG_CP15_INVAL_DC_LINE_SW     \
    :                                     \
    : "r" (param)                         \
  );

// }}}
////////////////////////////////////////////////////////////
// IO
////////////////////////////////////////////////////////////
// {{{
// ref: http://www.makelinux.net/ldd3/chp-9-sect-4
// http://blog.kmckk.com/archives/3072368.html
static inline void Xil_Out32(UINTPTR Addr, u32 Value)
{
  printk("Xil_Out32\n");
  if (!request_mem_region(Addr, sizeof(u32), "pl310-cache")) {
      printk("request_mem_region failed.\n");
      return;
  }
  volatile u32 __iomem *LocalAddr = ioremap(Addr, sizeof(u32));
  printk("\t%x %x: %x\n", Addr, LocalAddr, Value);
  iowrite32(Value, LocalAddr);
  printk("\t%x %x: %x\n", Addr, LocalAddr, ioread32(LocalAddr));
  iounmap(LocalAddr);
  // volatile u32 *LocalAddr = (volatile u32 *)Addr;
  // *LocalAddr = Value;
}

static inline u32 Xil_In32(UINTPTR Addr)
{
  printk("Xil_In32\n");

  if (!request_mem_region(Addr, sizeof(u32), "arm,pl310-cache")) {
      printk("request_mem_region failed.\n");
      return;
  }
  volatile u32 __iomem *LocalAddr = ioremap(Addr, sizeof(u32));
  printk("\t%x %x: %x\n", Addr, LocalAddr, ioread32(LocalAddr));
  u32 LocalValue = ioread32(LocalAddr);
  printk("\t%x %x: %x\n", Addr, LocalAddr, LocalValue);
  iounmap(LocalAddr);
  return LocalValue;
  // u32 LocalValue = *LocalAddr;
  // return *(volatile u32 *) Addr;
}

// }}}
////////////////////////////////////////////////////////////
// L1Cache
////////////////////////////////////////////////////////////
// {{{
void Xil_L1DCacheFlush(void)
{
  printk("Xil_L1DCacheFlush\n");
  register u32 CsidReg, C7Reg;
  u32 CacheSize, LineSize, NumWays;
  u32 Way;
  u32 WayIndex, Set, SetIndex, NumSet;
  u32 currmask;

  currmask = mfcpsr();
  mtcpsr(currmask | IRQ_FIQ_MASK);

  /* Select cache level 0 and D cache in CSSR */
  mtcp(XREG_CP15_CACHE_SIZE_SEL, 0);

  CsidReg = mfcp(XREG_CP15_CACHE_SIZE_ID);

  /* Determine Cache Size */

  CacheSize = (CsidReg >> 13U) & 0x1FFU;
  CacheSize +=1U;
  CacheSize *=128U;    /* to get number of bytes */

  /* Number of Ways */
  NumWays = (CsidReg & 0x3ffU) >> 3U;
  NumWays += 1U;

  /* Get the cacheline size, way size, index size from csidr */
  LineSize = (CsidReg & 0x07U) + 4U;

  NumSet = CacheSize/NumWays;
  NumSet /= (0x00000001U << LineSize);

  Way = 0U;
  Set = 0U;

  /* Invalidate all the cachelines */
  for (WayIndex =0U; WayIndex < NumWays; WayIndex++) {
    for (SetIndex =0U; SetIndex < NumSet; SetIndex++) {
      C7Reg = Way | Set;
      /* Flush by Set/Way */

      asm_cp15_clean_inval_dc_line_sw(C7Reg);
      Set += (0x00000001U << LineSize);
    }
    Set = 0U;
    Way += 0x40000000U;
  }

  /* Wait for L1 flush to complete */
  dsb();
  mtcpsr(currmask);
}

void Xil_L1DCacheInvalidate(void)
{
  printk("Xil_L1DCacheInvalidate\n");
  register u32 CsidReg, C7Reg;
  u32 CacheSize, LineSize, NumWays;
  u32 Way, WayIndex, Set, SetIndex, NumSet;
  u32 currmask;

  currmask = mfcpsr();
  mtcpsr(currmask | IRQ_FIQ_MASK);

#ifdef __GNUC__
  // u32 stack_start,stack_end,stack_size;

  // stack_end = (u32)&_stack_end;
  // stack_start = (u32)&__undef_stack;
  // stack_size=stack_start-stack_end;
  //
  // /*Flush stack memory to save return address*/
  // Xil_DCacheFlushRange(stack_end, stack_size);
  Xil_L1DCacheFlush();
#endif

  /* Select cache level 0 and D cache in CSSR */
  mtcp(XREG_CP15_CACHE_SIZE_SEL, 0U);

  CsidReg = mfcp(XREG_CP15_CACHE_SIZE_ID);
  /* Determine Cache Size */
  CacheSize = (CsidReg >> 13U) & 0x1FFU;
  CacheSize +=1U;
  CacheSize *=128U;    /* to get number of bytes */

  /* Number of Ways */
  NumWays = (CsidReg & 0x3ffU) >> 3U;
  NumWays += 1U;

  /* Get the cacheline size, way size, index size from csidr */
  LineSize = (CsidReg & 0x07U) + 4U;

  NumSet = CacheSize/NumWays;
  NumSet /= (0x00000001U << LineSize);

  Way = 0U;
  Set = 0U;

  /* Invalidate all the cachelines */
  for (WayIndex =0U; WayIndex < NumWays; WayIndex++) {
    for (SetIndex =0U; SetIndex < NumSet; SetIndex++) {
      C7Reg = Way | Set;

    /* Invalidate by Set/Way */
      asm_cp15_inval_dc_line_sw(C7Reg);
      Set += (0x00000001U << LineSize);
    }
    Set=0U;
    Way += 0x40000000U;
  }

  /* Wait for L1 invalidate to complete */
  dsb();
  mtcpsr(currmask);
}

void Xil_L1DCacheEnable(void)
{
  printk("Xil_L1DCacheEnable\n");
  register u32 CtrlReg;

  /* enable caches only if they are disabled */
  CtrlReg = mfcp(XREG_CP15_SYS_CONTROL);
  if ((CtrlReg & (XREG_CP15_CONTROL_C_BIT)) != 0U) {
    return;
  }

  /* clean and invalidate the Data cache */
  Xil_L1DCacheInvalidate();

  /* enable the Data cache */
  CtrlReg |= (XREG_CP15_CONTROL_C_BIT);

  mtcp(XREG_CP15_SYS_CONTROL, CtrlReg);
}

void Xil_L1DCacheDisable(void)
{
  printk("Xil_L1DCacheDisable\n");
  register u32 CtrlReg;

  /* clean and invalidate the Data cache */
  Xil_L1DCacheFlush();

  /* disable the Data cache */
  CtrlReg = mfcp(XREG_CP15_SYS_CONTROL);

  CtrlReg &= ~(XREG_CP15_CONTROL_C_BIT);

#if 0
  mtcp(XREG_CP15_SYS_CONTROL, CtrlReg);
#endif
}

// }}}
////////////////////////////////////////////////////////////
// L2Cache
////////////////////////////////////////////////////////////
// {{{
static inline void Xil_L2WriteDebugCtrl(u32 Value)
{
  printk("Xil_L2WriteDebugCtrl\n");
#if defined(CONFIG_PL310_ERRATA_588369) || defined(CONFIG_PL310_ERRATA_727915)
  Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_DEBUG_CTRL_OFFSET, Value);
#else
  (void)(Value);
#endif
}

static inline void Xil_L2CacheSync(void)
{
  printk("Xil_L2CacheSync\n");
#ifdef CONFIG_PL310_ERRATA_753970
  Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_DUMMY_CACHE_SYNC_OFFSET, 0x0U);
#else
  Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_SYNC_OFFSET, 0x0U);
#endif
}

void Xil_L2CacheFlush(void)
{
  printk("Xil_L2CacheFlush\n");
  u32 ResultL2Cache;

  /* Flush the caches */

  /* Disable Write-back and line fills */
  Xil_L2WriteDebugCtrl(0x3U);

#if 1
  printk("debug: %d\n", Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET));
  Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET,
            0x0000FFFFU);
#endif

  ResultL2Cache = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET)
                & 0x0000FFFFU;

  while(ResultL2Cache != (u32)0U) {
    ResultL2Cache = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INV_CLN_WAY_OFFSET)
                  & 0x0000FFFFU;
  }

  Xil_L2CacheSync();

  /* Enable Write-back and line fills */
  Xil_L2WriteDebugCtrl(0x0U);

  /* synchronize the processor */
  dsb();
}

void Xil_L2CacheInvalidate(void)
{
  printk("Xil_L2CacheInvalidate\n");
  #ifdef __GNUC__
  // u32 stack_start,stack_end,stack_size;
  // stack_end = (u32)&_stack_end;
  // stack_start = (u32)&__undef_stack;
  // stack_size=stack_start-stack_end;
  //
  // /*Flush stack memory to save return address*/
  // Xil_DCacheFlushRange(stack_end, stack_size);
  Xil_L2CacheFlush();
  #endif

  u32 ResultDCache;
  /* Invalidate the caches */
  Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INVLD_WAY_OFFSET,
            0x0000FFFFU);

  ResultDCache = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INVLD_WAY_OFFSET)
               & 0x0000FFFFU;

  while(ResultDCache != (u32)0U) {
    ResultDCache = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CACHE_INVLD_WAY_OFFSET)
                 & 0x0000FFFFU;
  }

  /* Wait for the invalidate to complete */
  Xil_L2CacheSync();

  /* synchronize the processor */
  dsb();
}

void Xil_L2CacheEnable(void)
{
  printk("Xil_L2CacheEnable\n");
  register u32 L2CCReg;

  L2CCReg = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CNTRL_OFFSET);

  /* only enable if L2CC is currently disabled */
  if ((L2CCReg & 0x01U) == 0U) {
    /* set up the way size and latencies */
    L2CCReg = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_AUX_CNTRL_OFFSET);
    L2CCReg &= XPS_L2CC_AUX_REG_ZERO_MASK;
    L2CCReg |= XPS_L2CC_AUX_REG_DEFAULT_MASK;

    Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_AUX_CNTRL_OFFSET,
              L2CCReg);
    Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_TAG_RAM_CNTRL_OFFSET,
              XPS_L2CC_TAG_RAM_DEFAULT_MASK);
    Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_DATA_RAM_CNTRL_OFFSET,
              XPS_L2CC_DATA_RAM_DEFAULT_MASK);

    /* Clear the pending interrupts */
    L2CCReg = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_ISR_OFFSET);

    Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_IAR_OFFSET, L2CCReg);

    Xil_L2CacheInvalidate();

    /* Enable the L2CC */
    L2CCReg = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CNTRL_OFFSET);

    Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_CNTRL_OFFSET,
              (L2CCReg | (0x01U)));

    Xil_L2CacheSync();

    /* synchronize the processor */
    dsb();
  }
}

void Xil_L2CacheDisable(void)
{
  printk("Xil_L2CacheDisable\n");
  register u32 L2CCReg;

  L2CCReg = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CNTRL_OFFSET);

  if((L2CCReg & 0x1U) != 0U) {

    /* Clean and Invalidate L2 Cache */
    Xil_L2CacheFlush();

    /* Disable the L2CC */
    L2CCReg = Xil_In32(XPS_L2CC_BASEADDR + XPS_L2CC_CNTRL_OFFSET);

    Xil_Out32(XPS_L2CC_BASEADDR + XPS_L2CC_CNTRL_OFFSET,
              (L2CCReg & (~0x01U)));
    /* Wait for the cache operations to complete */

    dsb();
  }
}

// }}}
////////////////////////////////////////////////////////////
// DCache
////////////////////////////////////////////////////////////
// {{{
void Xil_DCacheFlush(void)
{
  printk("Xil_DCacheFlush\n");
  u32 currmask;

  currmask = mfcpsr();
  mtcpsr(currmask | IRQ_FIQ_MASK);

  Xil_L1DCacheFlush();
  Xil_L2CacheFlush();

  mtcpsr(currmask);
}

void Xil_DCacheFlushRange(INTPTR adr, u32 len)
{
  printk("Xil_DCacheFlushRange\n");
  u32 LocalAddr = adr;
  const u32 cacheline = 32U;
  u32 end;
  u32 currmask;
  volatile u32 *L2CCOffset = (volatile u32 *)(XPS_L2CC_BASEADDR +
            XPS_L2CC_CACHE_INV_CLN_PA_OFFSET);

  currmask = mfcpsr();
  mtcpsr(currmask | IRQ_FIQ_MASK);

  if (len != 0U) {
    /* Back the starting address up to the start of a cache line
     * perform cache operations until adr+len
     */
    end = LocalAddr + len;
    LocalAddr &= ~(cacheline - 1U);

    while (LocalAddr < end) {

      /* Flush L1 Data cache line */
      asm_cp15_clean_inval_dc_line_mva_poc(LocalAddr);
      /* Flush L2 cache line */
      *L2CCOffset = LocalAddr;
      Xil_L2CacheSync();
      LocalAddr += cacheline;
    }
  }
  dsb();
  mtcpsr(currmask);
}

void Xil_DCacheEnable(void)
{
  printk("Xil_DCacheEnable\n");
  // Xil_L1DCacheEnable();
  Xil_L2CacheEnable();
}

void Xil_DCacheDisable(void)
{
  printk("Xil_DCacheDisable\n");
  Xil_L2CacheDisable();
  // Xil_L1DCacheDisable();
}
// }}}

static int __init switchdcache_init(void)
{
#ifdef __GNUC__
  printk("__GNUC__\n");
#endif
#ifndef USE_AMP
  printk("!USE_AMP\n");
#endif
  // Xil_DCacheDisable();
  flush_cache_all();

  return 0;
}


static void __exit switchdcache_exit(void)
{
  // Xil_DCacheEnable();
  flush_cache_all();
}

module_init(switchdcache_init);
module_exit(switchdcache_exit);
