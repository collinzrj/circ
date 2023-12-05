use std::collections::HashMap;
use crate::ir::term::*;
use super::visit::{ProgressAnalysisPass, RewritePass};

pub enum ShortIntegerAdjustmentAnalysisStage {
    FirstStage,
    SecondStage
}

pub struct ShortIntegerAdjustmentAnalysis {
    // is required, bitwidth, parents
    // bv_graph: HashMap<Term, (bool, usize, Vec<Term>)>,
    pub mode: ShortIntegerAdjustmentAnalysisStage,
    pub adjustment_required: HashMap<Term, bool>,
    // pub constraint_system: Vec<>
}

impl ShortIntegerAdjustmentAnalysis {
    fn visit_annotate_adjustment_required(&mut self, term: &Term) -> bool {
        match &term.op() {
            Op::Eq => {
                for child in term.cs() {
                    self.adjustment_required.insert(child.clone(), true);
                }
            },
            Op::BvBinOp(op) => {
                let children_adjustment_required = match op {
                    // TODO: are these only two not congruent?
                    BvBinOp::Udiv => true,
                    BvBinOp::Urem => true,
                    _ => false
                };
                if children_adjustment_required {
                    for child in term.cs() {
                        self.adjustment_required.insert(child.clone(), true);
                    }
                }
            },
            Op::BvBinPred(_) => {
                for child in term.cs() {
                    self.adjustment_required.insert(child.clone(), true);
                }
            },
            Op::BvNaryOp(op) => {
                let children_adjustment_required = match op {
                    // TODO: check if other also need adjustment
                    BvNaryOp::Add => {
                        let children_size_list: Vec<usize> = term.cs().iter()
                            .map(|bv| {
                                if let Sort::BitVector(n) = check(bv) {
                                    n
                                } else {
                                    panic!("{} is not a bit-vector in embed_bv", bv);
                                }
                            })
                            .collect();
                        // should adjust if size are not all the same
                        !children_size_list.iter().all(|&item| item == children_size_list[0])
                    },
                    _ => false
                };
                if children_adjustment_required {
                    for child in term.cs() {
                        self.adjustment_required.insert(child.clone(), true);
                    }
                }
            },
            // TODO: what does this do?
            Op::BvExtract(_, _) => todo!(),
            Op::BvConcat => {
                for child in term.cs() {
                    self.adjustment_required.insert(child.clone(), true);
                }
            },
            // TODO: what does this do?
            Op::BvUext(_) => todo!(),
            // TODO: what does this do?
            Op::BvSext(_) => todo!(),
            Op::BvToFp => {
                for child in term.cs() {
                    self.adjustment_required.insert(child.clone(), true);
                }
            },
            Op::UbvToFp(_) => {
                for child in term.cs() {
                    self.adjustment_required.insert(child.clone(), true);
                }
            },
            Op::SbvToFp(_) => {
                for child in term.cs() {
                    self.adjustment_required.insert(child.clone(), true);
                }
            },
            Op::UbvToPf(_) => {
                for child in term.cs() {
                    self.adjustment_required.insert(child.clone(), true);
                }
            },
            // TODO: **do we need adjustment for array and tuple? why?**
            Op::Store => todo!(),
            Op::CStore => todo!(),
            Op::Array(_, _) => todo!(),
            Op::Tuple => todo!(),
            Op::Update(_) => todo!(),
            _ => ()
        };
        true
    }

    fn visit_build_constraint_system(&mut self, term: &Term) -> bool {
        if self.adjustment_required.contains_key(term) {
            // if let Value::BitVector(b) = &term.op() {
            //     b
            // }
            // match term.op() {
            //     Some(bv) => bv.update_adjust(true),
            //     _ => false,
            // }
            return false;
        } else {
            return false;
        };
    }
}

impl ProgressAnalysisPass for ShortIntegerAdjustmentAnalysis {
    fn visit(&mut self, term: &Term) -> bool {
        match self.mode {
            ShortIntegerAdjustmentAnalysisStage::FirstStage => self.visit_annotate_adjustment_required(term),
            ShortIntegerAdjustmentAnalysisStage::SecondStage => self.visit_build_constraint_system(term),
        }
    }
}

pub struct ShortIntegerAdjustmentRewrite {
    pub adjustment_required: HashMap<Term, bool>,
}

impl RewritePass for ShortIntegerAdjustmentRewrite {
    fn visit<F: Fn() -> Vec<Term>>(
        &mut self,
        computation: &mut Computation,
        orig: &Term,
        rewritten_children: F,
    ) -> Option<Term> {
        if !self.adjustment_required.contains_key(orig) {
            match check(orig) {
                Sort::BitVector(_) => {
                    match orig.op() {
                        Op::BvNaryOp(bvop) => Some(term(Op::BvNaryOpNotAdjust(bvop.clone()), rewritten_children())),
                        _ => None
                    }
                },
                _ => panic!("This must be bitvector!")
            }
        } else {
            None
        }
    }
}