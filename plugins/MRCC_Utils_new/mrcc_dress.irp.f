subroutine mrcc_dress(ndetref,ndetnonref,nstates,delta_ij_,delta_ii_)
 use bitmasks
 implicit none
 integer, intent(in) :: ndetref,nstates,ndetnonref
 double precision, intent(inout) :: delta_ii_(ndetref,nstates),delta_ij_(ndetref,ndetnonref,nstates)
 integer :: i,j,k,l
 integer :: i_state
 integer :: N_connect_ref
 integer*2,allocatable  :: excitation_operators(:,:)
 double precision, allocatable :: amplitudes_phase_less(:)
 double precision, allocatable :: coef_test(:)
 integer(bit_kind), allocatable :: key_test(:,:)
 integer, allocatable :: index_connected(:)
 integer :: i_hole,i_particle,ispin,i_ok,connected_to_ref,index_wf
 integer, allocatable :: idx_vector(:), degree_vector(:)
 double precision :: phase_ij
 double precision :: dij,phase_la
 double precision :: hij,phase
 integer :: exc(0:2,2,2),degree
 logical :: is_in_wavefunction
 allocate(excitation_operators(5,N_det_non_ref))
 allocate(amplitudes_phase_less(N_det_non_ref))
 allocate(key_test(N_int,2))
 allocate(index_connected(N_det_non_ref))
 allocate(idx_vector(0:N_det_non_ref))
 allocate(degree_vector(N_det_non_ref))
 i_state = 1

 do i = 1, N_det_ref
  call get_excitation_operators_for_one_ref(psi_ref(1,1,i),i_state,N_det_non_ref,N_connect_ref,excitation_operators,amplitudes_phase_less,index_connected)
  print*,'N_connect_ref =',N_connect_ref
  do l = 1, N_det_non_ref
    double precision :: t_il,phase_il,hil
    call i_H_j_phase_out(psi_ref(1,1,i),psi_non_ref(1,1,l),N_int,hil,phase_il,exc,degree)
    t_il = hil * lambda_mrcc(i_state,l) 
    ! loop on the non ref determinants 
    do j = 1, N_connect_ref
    ! loop on the excitation operators linked to i
      if(j==l)cycle
      do k = 1, N_int
       key_test(k,1) = psi_non_ref(k,1,l)
       key_test(k,2) = psi_non_ref(k,2,l)
      enddo
       ! we apply the excitation operator T_I->j
       call apply_excitation_operator(key_test,excitation_operators(1,j),i_ok)
       if(i_ok.ne.1)cycle
       ! we check if such determinant is already in the wave function 
       if(is_in_wavefunction(key_test,N_int,N_det))cycle
       ! we get the phase for psi_non_ref(l) -> T_I->j |psi_non_ref(l)>
       call get_excitation(psi_non_ref(1,1,l),key_test,exc,degree,phase_la,N_int)
       ! we get the phase T_I->j
       call i_H_j_phase_out(psi_ref(1,1,i),psi_non_ref(1,1,index_connected(j)),N_int,hij,phase_ij,exc,degree)
       ! we compute the contribution to the coef of key_test
       dij =   t_il *  hij * phase_la *phase_ij *lambda_mrcc(i_state,index_connected(j)) * 0.5d0
       ! we compute the interaction of such determinant with all the non_ref dets
       call get_excitation_degree_vector(psi_non_ref,key_test,degree_vector,N_int,N_det_non_ref,idx_vector)
       do k = 1, idx_vector(0) 
        call i_H_j_phase_out(key_test,psi_non_ref(1,1,idx_vector(k)),N_int,hij,phase,exc,degree)
        delta_ij_(i,idx_vector(k),i_state) += hij * dij
       enddo
    enddo
    if(dabs(psi_ref_coef(i,i_state)).le.5.d-5)cycle
!   delta_ij_(i,l,i_state) = delta_ij_(i,l,i_state) * 0.5d0
    delta_ii_(i,i_state) -= delta_ij_(i,l,i_state) * psi_non_ref_coef(l,i_state) / psi_ref_coef(i,i_state)
  enddo
 enddo

 deallocate(excitation_operators)
 deallocate(amplitudes_phase_less)
 deallocate(key_test)
 deallocate(idx_vector)
 deallocate(degree_vector)

end



subroutine apply_excitation_operator(key_in,excitation_operator,i_ok)
 use bitmasks
 implicit none
 integer(bit_kind), intent(inout) :: key_in
 integer, intent (out) :: i_ok
 integer*2 :: excitation_operator(5)
 integer :: i_particle,i_hole,ispin
 ! Do excitation 
   if(excitation_operator(5)==1)then ! mono alpha
    i_hole = excitation_operator(1)
    i_particle = excitation_operator(2)
    ispin = 1
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
   else if (excitation_operator(5)==-1)then  ! mono beta 
    i_hole = excitation_operator(3)
    i_particle = excitation_operator(4)
    ispin = 2
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
   else if (excitation_operator(5) == -2 )then ! double beta 
    i_hole = excitation_operator(1)
    i_particle = excitation_operator(2)
    ispin = 2
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
    if(i_ok.ne.1)return
    i_hole = excitation_operator(3)
    i_particle = excitation_operator(4)
    ispin = 2
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
   
   else if (excitation_operator(5) ==  2 )then ! double alpha 
    i_hole = excitation_operator(1)
    i_particle = excitation_operator(2)
    ispin = 1
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
    if(i_ok.ne.1)return
    i_hole = excitation_operator(3)
    i_particle = excitation_operator(4)
    ispin = 1
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
 
   else if (excitation_operator(5) ==  0 )then ! double alpha/alpha 
    i_hole = excitation_operator(1)
    i_particle = excitation_operator(2)
    ispin = 1
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
    if(i_ok.ne.1)return
    i_hole = excitation_operator(3)
    i_particle = excitation_operator(4)
    ispin = 2
    call do_mono_excitation(key_in,i_hole,i_particle,ispin,i_ok)
   endif
end
